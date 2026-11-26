const fs = require('node:fs');
const path = require('node:path');

const dir = path.join(process.argv[2], '.codex');
const file = path.join(dir, 'hooks.json');
const command = 'echo "Use the installed Caveman skill in full mode for this session until I say stop caveman or normal mode."';
const config = {
  hooks: {
    SessionStart: [{
      matcher: '^startup$',
      hooks: [{ type: 'command', command, statusMessage: 'Starting Caveman mode' }],
    }],
  },
};
const contents = `${JSON.stringify(config, null, 2)}\n`;

fs.mkdirSync(dir, { recursive: true });
try {
  fs.writeFileSync(file, contents, { flag: 'wx' });
} catch (error) {
  if (error.code !== 'EEXIST') throw error;
  let existing;
  try {
    existing = JSON.parse(fs.readFileSync(file, 'utf8').replace(/^\uFEFF/, ''));
  } catch (error) {
    if (!(error instanceof SyntaxError)) throw error;
  }
  const startup = existing?.hooks?.SessionStart;
  if (!Array.isArray(startup) || !startup.some(group =>
    group?.matcher === '^startup$' && Array.isArray(group.hooks) &&
    group.hooks.some(hook => hook?.type === 'command' && hook.command === command))) {
    const proposal = `${file}.kit-new`;
    try {
      fs.writeFileSync(proposal, contents, { flag: 'wx' });
    } catch (error) {
      if (error.code !== 'EEXIST' || fs.readFileSync(proposal, 'utf8') !== contents) throw error;
    }
    console.log('merge');
  }
}
