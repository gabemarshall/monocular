#!/usr/bin/env node
const dns = require("dns-then");
const Promise = require("bluebird");
const fs = require("fs");
const dns_reg = require('dns');
const argv = require("yargs").argv;
const cheerio = require('cheerio');

var resolvers = ["8.8.8.8", "8.8.4.4", "1.1.1.1"];

async function getNameServers() {
  dns
    .resolveNs(argv.domain)
    .then(function(address) {
      if (Array.isArray(address)) {
        console.log(address.length + " additional nameservers found");
        console.log();
        for (i = 0; i < address.length; i++) {
          let tempNs = address[i].toString().trim();

          dns.lookup(tempNs).then(function(rec) {
            resolvers.push(rec);
          });
        }
      }
    })
    .then(function() {});
}




function checkCName(address) {
  return new Promise(function(resolve, reject) {
      var result = address
      for (i=0;i<5;i++){
        console.log("test")
      }
      if (result != null) {
        dns.lookup(address[0]).then(function(res){
          resolve(res) 
        })
      } else {
        reject(new Error('User cancelled'));
      }
    });
}

let wordlist = argv.wordlist;
if (!wordlist) {
  wordlist = "lib/tiny.txt";
}
let words = fs
  .readFileSync(wordlist, "utf-8")
  .trim()
  .split("\n");
let domain = argv.domain;
let takeover = argv.takeover;

async function setNameServers() {
  return dns.setServers(resolvers);
}

(async () => {
  console.log("Enumerating " + argv.domain + "\n");
  if (argv.o) {
    console.log("Output will be saved in " + argv.o);
  }

  await getNameServers();
  await setNameServers();

  setTimeout(function() {
    dns.setServers(resolvers);
    let wcCheck = "tazooflwoa1";
    words.unshift(wcCheck);
    return Promise.map(
      words,
      function(sub) {
        let subdomain = sub + "." + domain;
        
        let resolv = dns.resolveCname;
        
        resolv(subdomain).then(function(address) {
          if (address) {
            if (subdomain.includes(wcCheck)) {
              console.log("Wildcard detected, quitting");
              process.exit(0);
            }
            out = "Found: " + subdomain + " [" + address + "]";

            checkCName(address).then(function(res){
              console.log(res)
            })

            if (argv.o) {
              out += "\n";
              if (argv.csv){
                fs.appendFileSync(argv.o, subdomain+","+address+"\n")
              } else {
                fs.appendFileSync(argv.o, out);
              }
              
            }
          }
        });
      },
      {
        concurrency: 5000
      }
    ).then(function() {});
  }, 500);
})();
