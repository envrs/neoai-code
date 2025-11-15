import { template } from "./template.html";

export const PART_OF_A_TEAM_MESSAGE = `
<h3>Welcome to Neoai Chat</h3>
<h4>Neoai Chat is currently in Beta</h4>
<p>To use Neoai chat please make sure you are part of a team.</p>`;

export const html = (logoSrc: string) =>
  template(PART_OF_A_TEAM_MESSAGE, logoSrc);
