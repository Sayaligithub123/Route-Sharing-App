const http = require('http');

const respondToRequest = () => {
  const options = {
    hostname: 'localhost',
    port: 5000,
    path: '/api/rides/respond',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
  };

  const req = http.request(options, (res) => {
    let data = '';
    res.on('data', (chunk) => {
      data += chunk;
    });
    res.on('end', () => {
      console.log('Respond to Request response:', res.statusCode, data);
    });
  });

  req.on('error', (e) => {
    console.error(`Problem with request: ${e.message}`);
  });

  req.write(JSON.stringify({
    requestId: '69faeb01112787f5dd8703d1', // From previous response
    status: 'accepted'
  }));
  req.end();
};

respondToRequest();
