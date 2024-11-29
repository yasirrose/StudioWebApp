import axios from 'axios';
import https from 'https';

const api = axios.create({
  httpsAgent: new https.Agent({
    rejectUnauthorized: false, // Ignore SSL certificate errors for development
  }),
});

export default api;
