const http = require('http');
const fs = require('fs');
const path = '/etc/shared/environment/CONTROL_PLANE_STATUS';

function getControlPlaneStatus() {
    try {
        if (!fs.existsSync(path)) {
            return 'false';
        }
        const status = fs.readFileSync(path, 'utf8').trim();
        return status === 'running' ? 'true' : 'false';
    } catch (err) {
        return 'false';
    }
}

const server = http.createServer((req, res) => {
    if (req.url === '/ready' && req.method === 'GET') {
        const response = getControlPlaneStatus();
        res.writeHead(200, { 'Content-Type': 'text/plain' });
        res.end(response);
    } else {
        res.writeHead(404, { 'Content-Type': 'text/plain' });
        res.end('false');
    }
});

server.listen(80, () => {
    console.log('Server running on port 80...');
});
