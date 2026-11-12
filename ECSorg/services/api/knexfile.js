const fs = require('fs');

if (fs.existsSync('./config.json')) {
	module.exports = JSON.parse(fs.readFileSync('./config.json').toString()).knex;
} else {
	module.exports = {
		client: 'pg',
		connection: {
			host: process.env.DB_HOST || '127.0.0.1',
			port: Number(process.env.DB_PORT || 5432),
			user: process.env.DB_USER || 'postgres',
			password: process.env.DB_PASSWORD || 'postgres',
			database: process.env.DB_NAME || 'roblox'
		}
	};
}