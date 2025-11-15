import { template } from "./template.html";

export const WELCOME_MESSAGE = `
<h3>Welcome to Neoai Chat</h3>
<h4>Neoai Chat is currently in Beta</h4>
<p>We understand that waiting for this awesome feature isn’t easy, but we guarantee it will be worth it. 
Neoai Chat will soon be available to all users, and we'll make sure to keep you informed. Thank you for your patience!
<a href="https://www.neoai.com/#ChatSection">Learn More</a></p>`;

export const html = (logoSrc: string) => template(WELCOME_MESSAGE, logoSrc);
