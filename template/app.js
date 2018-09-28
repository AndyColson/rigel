function goLeft() {
	$.getJSON('/left', function(data) {
		setTimeout(getStatus, 2000);
		console.log("setTimeout");
	});
}

function getStatus() {
	console.log('getStatus');
	$.getJSON('/status', function(data) {
		document.getElementById('status').innerHTML = data.status;
	});
}
