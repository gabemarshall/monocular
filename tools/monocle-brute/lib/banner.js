const net = require('net');
const PromiseSocket = require('promise-socket');
const { PromiseReadablePiping } = require('promise-piping');
const ReadlineTransform = require('readline-transform');
const Promise = require('bluebird');

// const socket = new net.Socket()
// const promiseSocket = new PromiseSocket(socket)


async function getBanners(services) {
	
     return Promise.map(services, function(service) {

	var client = new net.Socket();
	let isOpen = false;
	client.connect(service.port, service.ip, function() {
		console.log("Port "+service.port+" on "+service.ip+" is open")
		isOpen = true;
		client.write('HEAD / HTTP/1.1\r\n\r\n');
	});
	setTimeout(function(){
		if (!client.destroyed && !isOpen){
			console.log("Port "+service.port+" on "+service.ip+" is closed")
		}
		client.destroy();
	}, 1500)

	client.on('data', function(data) {
		console.log(data.toString());
		client.destroy();
	});

	client.on('close', function() {
		
	});

    }, {
        concurrency: 50
    }).then(function(){
    	console.log("done")
    })

}

(async () => {
	services = [{ip: '10.15.34.145', port: 8000}]
	services.push({ip: '155.199.192.27', port: 80})
	services.push({ip: '155.199.192.27', port: 443})
	services.push({ip: '155.199.192.27', port: 21})
	services.push({ip: '155.199.192.27', port: 251})
	services.push({ip: '155.199.192.27', port: 443})
	services.push({ip: '155.199.192.27', port: 443})
	services.push({ip: '155.199.192.27', port: 443})
	services.push({ip: '155.199.192.27', port: 443})
	services.push({ip: '155.199.192.27', port: 443})
	services.push({ip: '155.199.192.27', port: 443})
	services.push({ip: '155.199.192.27', port: 443})
	services.push({ip: '155.199.192.27', port: 443})
	services.push({ip: '155.199.192.27', port: 443})
	services.push({ip: '10.15.34.145', port: 8000})
	services.push({ip: '10.15.34.145', port: 8000})
	services.push({ip: '10.15.34.145', port: 8000})
	services.push({ip: '10.15.34.145', port: 8000})
	services.push({ip: '10.15.34.145', port: 8000})
	services.push({ip: '10.15.34.145', port: 8000})
	services.push({ip: '10.15.34.145', port: 8000})
	services.push({ip: '10.15.34.145', port: 8000})
	services.push({ip: '10.15.34.145', port: 8000})
	services.push({ip: '10.15.34.145', port: 8000})
	services.push({ip: '10.15.34.145', port: 8000})
	services.push({ip: '10.15.34.145', port: 8000})
	services.push({ip: '10.15.34.145', port: 8000})
	services.push({ip: '10.15.34.145', port: 8000})
	services.push({ip: '10.15.34.145', port: 8000})
	services.push({ip: '10.15.34.145', port: 8000})
	services.push({ip: '10.15.34.145', port: 8000})
	services.push({ip: '10.15.34.145', port: 8000})
	services.push({ip: '10.15.34.145', port: 8000})
	services.push({ip: '10.15.34.145', port: 8000})
	services.push({ip: '10.15.34.145', port: 8000})
	await getBanners(services)
})();

module.exports = getBanners;