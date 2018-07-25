'use strict';

const dns = require("dns-then");
const Promise = require("bluebird");
const fs = require("fs");
const argv = require("yargs").argv;

module.exports.hello = (event, context, callback) => {
  let domain = 'eversec.rocks'
  var resolvers = ["8.8.8.8", "8.8.4.4", "1.1.1.1"];
async function getNameServers() {
  dns
    .resolveNs(domain)
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

let wordlist = argv.wordlist;
if (!wordlist) {
  wordlist = "lib/default.txt";
}
let words = fs
  .readFileSync(wordlist, "utf-8")
  .trim()
  .split("\n");


let results = []


async function setNameServers() {
  return dns.setServers(resolvers);
}

(async () => {
  console.log("Enumerating " + domain + "\n");
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

        dns.lookup(subdomain).then(function(address) {
          if (address) {
            if (subdomain.includes(wcCheck)) {
              console.log("Wildcard detected, quitting");
              process.exit(0);
            }
            out = "Found: " + subdomain + " [" + address + "]";
            console.log(out);
            results.push(out);
            if (argv.o) {
              out += "\n";
              fs.appendFileSync(argv.o, out);
            }
          }
        });
      },
      {
        concurrency: 5000
      }
    ).then(function() {
  const response = {
    statusCode: 200,
    body: JSON.stringify(results),
  };

  callback(null, response);
    });
  }, 500);
})();




  // Use this code if you don't use the http event with the LAMBDA-PROXY integration
  // callback(null, { message: 'Go Serverless v1.0! Your function executed successfully!', event });
};