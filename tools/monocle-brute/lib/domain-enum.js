const { Resolver } = require("dns");
const resolver = new Resolver();
const throttledQueue = require("throttled-queue");
const fs = require("fs");
const args = require("yargs");

exports.brute = async function(target) {
  let counter = 0
  function uniq(arr) {
    if (arr.length === 0) return arr;
    arr = arr.sort(function(a, b) {
      return a * 1 - b * 1;
    });
    var ret = [arr[0]];
    for (var i = 1; i < arr.length; i++) {
      if (arr[i - 1] !== arr[i]) {
        ret.push(arr[i]);
      }
    }
    return ret;
  }

  console.log(target);
  let rate = 5000;
  let discoveries = [];
  let words = [];
  let tempFile = fs
    .readFileSync("./lib/default.txt")
    .toString()
    .split("\n");

  // Clean up words from brute list
  for (i = 0; i < tempFile.length; i++) {
    words.push(tempFile[i].toLowerCase().trim());
  }
  words = uniq(words);
  let jobCount = words.length;
  let throttle = throttledQueue(rate, 1000, false);



  let resolvers = ["8.8.8.8", "8.8.4.4", "1.1.1.1"];
  resolver.resolveNs(target, function(err, rec) {
    if (err) {
      console.log(err);
    }
    if (Array.isArray(rec)) {
      for (i = 0; i < rec.length; i++) {
        let tempNs = rec[i].toString().trim();
        let ns = resolver.resolve(tempNs, "A", function(err, ip) {
          if (err) {
            console.log("error");
          } else {
            resolvers.push(ip[0]);
          }
        });
      }
      console.log("Grabbing name servers...")
      setTimeout(function() {
        function check(){
          count = jobCount - words.length;
          
          // if ((count % rate) === 0) {
          // var perCompleted = Math.round(((count / jobCount) * 100));
          // if (perCompleted != 0){
          //   perCompleted = perCompleted.toString();
          //   perCompleted += '% completed';
          //   if ((count % 1000) === 0){
          //       console.log("[*] "+perCompleted);
          //   }
          // }
      
          // }
          if (counter === jobCount){
            
              console.log("100% completed")
              console.log("Waiting for jobs to finish..")
              console.log(discoveries.length)     
              setTimeout(function(){
                console.log(discoveries.length+" domains discovered")
                for (i=0;i<discoveries.length;i++){
                  //console.log(discoveries[i].domain);
                }
              }, 10000)
          } else {
          }      
        }

        let dnsJob = function(resolver, word, target) {
          let guess = word + "." + target;
          resolver.resolve(guess, "A", function(err, ip) {      
            if (err) {
              
            } else {
              console.log(guess+" => "+ip[0]);
              discoveries.push({domain: guess, record: ip[0]})
            }
            counter++
            check()
            
          });    
          
          
        };        
        let total_requests = jobCount;
        //resolver.setServers(resolvers);
        console.log("Starting job")
        for (i = 0; i < words.length; i++) {
          throttle(function() {
            word = words.splice(0, 1);
            dnsJob(resolver, word[0], target);
          });
        }

      }, 1500);
    }
  });

  return "hi";
};

exports.enum = async function(target) {
  let results = await exports.brute(target);

  return results;
};
