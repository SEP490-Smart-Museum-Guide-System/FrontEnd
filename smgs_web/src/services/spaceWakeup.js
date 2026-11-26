const SPACE_READY_ENDPOINTS = [
  'https://trungnam1644-smgs-ai-quiz.hf.space/ready',
  'https://trungnam1644-smgs-ai-guide.hf.space/ready',
];

let wakeStarted = false;

// Fire once when the web app boots. The public readiness routes wake sleeping
// Spaces without sending AI input or exposing either service key to the browser.
export function wakeAiSpacesOnAppOpen() {
  if (wakeStarted) return;
  wakeStarted = true;

  for (const endpoint of SPACE_READY_ENDPOINTS) {
    fetch(endpoint, { method: 'GET', mode: 'no-cors', cache: 'no-store' }).catch(() => {});
  }
}
