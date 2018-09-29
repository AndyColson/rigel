function goLeft(dir) {
	$.getJSON('/'+dir, function(data) {
		setTimeout(getStatus, 2000);
		console.log("setTimeout");
	});
}

function getStatus() {
	console.log('getStatus');
	$.getJSON('/status', function(data) {
		document.getElementById('status').innerHTML = data.status
			+ '<br>RA: ' + data.ra
			+ '<br>DEC: ' + data.dec;
	});
}
