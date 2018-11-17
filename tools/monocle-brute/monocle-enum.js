const fs = require("fs");
const args = require("yargs");
const { spawn } = require("child_process");
const parser = require("xml2json");
const parseString = require("xml2js").parseString;
const domain = require("./lib/domain-enum");


exports.parse = function(xml) {
  results = [];
  parseString(xml, function(err, result) {
    var host = result.nmaprun.host;
    
    for (i = 0; i < host.length; i++) {
      var ip = host[i]["address"][0]["$"]["addr"];
      var ports = host[i]["ports"][0]["port"];

      //console.log(ports)
      ports.forEach(function(entry) {
        var port = entry["$"]["portid"];

        //console.log(ip+':'+port)
        var state = entry["state"][0]["$"]["state"];
        if (state === "open") {
          //console.log(entry['state'][0])
          var type = entry["service"][0]["$"]["name"];

          if (entry["script"]) {
            var banner = entry["script"][0]["$"]["output"].trim();
          } else {
            var banner = "Unknown";
          }

          var result = { ip: ip, port: port, banner: banner, type: type };
          results.push(result);
        }
      });
    }
  });
  return results
};

const child = spawn("nmap", [
  "-T4",
  "192.241.196.88",
  "-Pn",
  "-p3128",
  "-n",
  "--open",
  "--script=banner",
  "-oX",
  "foob.xml"
]);

child.stdout.on("data", data => {
  console.log(`child stdout:\n${data}`);
});

child.stdout.on("close", data => {
  console.log("done");
  file = fs.readFileSync('foob.xml', 'utf-8')
var xml = file.toString()
try {
  test = exports.parse(xml)
  console.log(test)
} catch(err){
  console.log("Error parsing nmap xml file")
}
});




//var jobType = "subdomain";
// var target = "contoso.com";
// if (jobType === "subdomain"){
// 	domain.brute(target);
// }

// dnsResolver.resolve(finalPayload + argv.domain, 'TXT', function(err, rec) {
// 	if (err) {
// 		console.log(err);
// 	}
// 	onMessage(rec, true);
// })
// file = fs.readFileSync('./test3.xml')
// xml = file.toString()

// test = exports.parse(xml)

// console.log(results)
