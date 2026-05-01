const fs = require('fs');
const path = require('path');

const PROJECTS_URL = 'https://inled.es/projects.json';
const README_PATHS = [
  path.join(__dirname, '../../README.md'),
  path.join(__dirname, '../../profile/README.md')
];

async function fetchProjects() {
  try {
    const response = await fetch(PROJECTS_URL, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (github-action-bot; jaimegh-portfolio-updater)'
      }
    });
    if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
    return await response.json();
  } catch (error) {
    console.error('Error fetching projects:', error);
    process.exit(1);
  }
}

function renderProjects(projects) {
  let html = '<table border="0">\n  <tr>\n';

  projects.forEach((project, index) => {
    // 3 cards per row
    if (index > 0 && index % 3 === 0) {
      html += '  </tr>\n  <tr>\n';
    }

    html += `    <td align="center" width="250" valign="top">
      <a href="${project.link}" target="_blank">
        <img src="${project.logo}" width="80" alt="${project.name} logo"><br>
        <b>${project.name}</b>
      </a><br>
      <sub>${project.description}</sub>
    </td>\n`;
  });

  // Close the last row with empty cells if needed
  const remaining = (3 - (projects.length % 3)) % 3;
  if (remaining > 0) {
    for (let i = 0; i < remaining; i++) {
      html += '    <td width="250"></td>\n';
    }
  }

  html += '  </tr>\n</table>\n\n';
  return html;
}

async function updateReadmes() {
  const projects = await fetchProjects();
  const projectsContent = renderProjects(projects);

  const startTag = '<!-- INLED-START -->';
  const endTag = '<!-- INLED-END -->';
  const regex = new RegExp(`${startTag}[\\s\\S]*${endTag}`, 'g');

  README_PATHS.forEach(readmePath => {
    if (fs.existsSync(readmePath)) {
      const readmeContent = fs.readFileSync(readmePath, 'utf8');
      const newContent = readmeContent.replace(regex, `${startTag}\n${projectsContent}${endTag}`);
      fs.writeFileSync(readmePath, newContent);
      console.log(`${path.basename(readmePath)} updated successfully.`);
    } else {
      console.warn(`File not found: ${readmePath}`);
    }
  });
}

updateReadmes();
