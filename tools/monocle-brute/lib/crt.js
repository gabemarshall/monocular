const axios = require('axios');
const cheerio = require('cheerio');
const uniq = require('array-unique');

var parseDomains = async function(html){
  let domains = []
  const $ = cheerio.load(html);
  let results = $('body > table:nth-child(8) > tbody> tr > td > table > tbody > tr > td:nth-child(5)');
  for (i=0;i<results.length;i++){
    domains.push(results[i].children[0].data)
  }
  return domains
}

const crt = async function(domain) {
  try {
    let domains = []
    const response = await axios({
      url: 'https://crt.sh/?q=%25.'+domain,
      timeout: 60000,
      method: 'GET'
    })
    
    let dom = await parseDomains(response.data)
    let uniqueResults = uniq(dom);

    return uniqueResults
      

    
    
  } catch (error) {
    console.error(error.response.data)
  }
};

module.exports = crt