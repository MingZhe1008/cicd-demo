async function loadRelease() {
  document.getElementById('version').textContent = window.RELEASE.version;
  document.getElementById('message').textContent = window.RELEASE.message;
  try {
    const response = await fetch('build.json', { cache: 'no-store' });
    if (!response.ok) throw new Error('HTTP ' + response.status);
    const info = await response.json();
    for (const key of ['commit', 'build', 'builtAt']) document.getElementById(key).textContent = info[key];
    document.getElementById('feedback').textContent = '';
  } catch {
    document.getElementById('feedback').textContent = '发布信息读取失败，请通过 HTTP 服务访问并检查网络。';
  }
}
document.getElementById('refresh').addEventListener('click', () => location.reload());
document.getElementById('copy').addEventListener('click', async () => {
  const summary = ['version', 'commit', 'build', 'builtAt'].map(key => key + ': ' + document.getElementById(key).textContent).join('\n');
  try {
    await navigator.clipboard.writeText(summary);
    document.getElementById('feedback').textContent = '发布信息已复制。';
  } catch {
    document.getElementById('feedback').textContent = '当前浏览器不支持复制，请手动记录右侧版本与提交信息。';
  }
});
loadRelease();
