const NONCE_PATTERN = /^[A-Za-z0-9_-]{22}$/;

export function renderResetPasswordPage(nonce: string): string {
  if (!NONCE_PATTERN.test(nonce)) {
    throw new Error('Invalid reset page nonce');
  }
  return `<!DOCTYPE html>
<html lang="th">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="referrer" content="no-referrer">
  <title>ตั้งรหัสผ่านใหม่ · InternFinder</title>
  <style nonce="${nonce}">
    :root { color-scheme: light; }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      min-height: 100vh;
      display: grid;
      place-items: center;
      padding: 24px 16px;
      background: #fdf8ee;
      color: #18181b;
      font-family: "Segoe UI", Tahoma, sans-serif;
    }
    main {
      width: min(100%, 440px);
      padding: 28px 24px;
      background: #fffbeb;
      border: 2px solid #18181b;
      border-radius: 16px;
      box-shadow: 6px 6px 0 #18181b;
    }
    h1 { margin: 0 0 8px; font-size: 1.6rem; }
    p { margin: 0 0 20px; line-height: 1.5; color: #4b5563; }
    label { display: block; margin: 16px 0 8px; font-weight: 700; }
    input {
      width: 100%;
      padding: 12px 14px;
      border: 2px solid #18181b;
      border-radius: 12px;
      background: #fff;
      font: inherit;
    }
    button {
      width: 100%;
      margin-top: 20px;
      padding: 14px 16px;
      border: 2px solid #18181b;
      border-radius: 12px;
      background: #fef08a;
      box-shadow: 4px 4px 0 #18181b;
      font: inherit;
      font-weight: 700;
      cursor: pointer;
    }
    button:disabled { cursor: wait; opacity: 0.7; }
    .feedback {
      margin-top: 16px;
      padding: 12px 14px;
      border: 2px solid #18181b;
      border-radius: 12px;
      line-height: 1.45;
    }
    .feedback.error { background: #fee2e2; }
    .feedback.ok { background: #a7f3d0; }
    [hidden] { display: none !important; }
  </style>
</head>
<body>
  <main>
    <h1>ตั้งรหัสผ่านใหม่</h1>
    <p id="lead">เลือกรหัสผ่านใหม่ที่มีอย่างน้อย 8 ตัวอักษร ต้องไม่ซ้ำกับรหัสผ่านเดิม และไม่ควรใช้รหัสผ่านเดียวกับบัญชีอื่น</p>
    <form id="reset-form" method="post" action="/reset-password" novalidate>
      <label for="password">รหัสผ่านใหม่</label>
      <input id="password" name="password" type="password" autocomplete="new-password" minlength="8" required>
      <p style="margin: 8px 0 0; font-size: 12px">อย่างน้อย 8 ตัว มี A–Z, a–z, ตัวเลข และสัญลักษณ์</p>
      <p id="requirements" style="margin: 4px 0 0; font-size: 12px" aria-live="polite" hidden></p>
      <label for="confirmation">ยืนยันรหัสผ่านใหม่</label>
      <input id="confirmation" name="confirmation" type="password" autocomplete="new-password" minlength="8" required>
      <button id="submit" type="submit">บันทึกรหัสผ่านใหม่</button>
    </form>
    <p id="feedback" class="feedback error" hidden></p>
    <p id="done" class="feedback ok" hidden>ตั้งรหัสผ่านใหม่เรียบร้อยแล้ว เปิดแอป InternFinder แล้วเข้าสู่ระบบด้วยรหัสผ่านใหม่</p>
    <noscript><p class="feedback error">เปิดใช้ JavaScript เพื่อตั้งรหัสผ่านจากลิงก์นี้</p></noscript>
  </main>
  <script nonce="${nonce}">
    const form = document.getElementById('reset-form');
    const lead = document.getElementById('lead');
    const feedback = document.getElementById('feedback');
    const done = document.getElementById('done');
    const submit = document.getElementById('submit');
    const password = document.getElementById('password');
    const confirmation = document.getElementById('confirmation');
    const requirements = document.getElementById('requirements');
    function missingConditions(next) {
      return [
        [Array.from(next).length >= 8, 'ให้ครบ 8 ตัว'],
        [/[A-Z]/.test(next), 'ตัวพิมพ์ใหญ่ A–Z'],
        [/[a-z]/.test(next), 'ตัวพิมพ์เล็ก a–z'],
        [/[0-9]/.test(next), 'ตัวเลข'],
        [/[\\x21-\\x2f\\x3a-\\x40\\x5b-\\x60\\x7b-\\x7e]/.test(next), 'สัญลักษณ์ เช่น ! @ #']
      ].filter(function (condition) { return !condition[0]; })
        .map(function (condition) { return condition[1]; });
    }
    password.addEventListener('input', function () {
      const missing = missingConditions(password.value);
      requirements.hidden = !password.value || !missing.length;
      requirements.textContent = missing.length ? 'เพิ่มอีก: ' + missing.join(', ') : '';
    });
    const tokenMatch = /^#token=([a-f0-9]{64})$/.exec(location.hash);
    const token = tokenMatch ? tokenMatch[1] : '';

    function showError(message) {
      feedback.textContent = message;
      feedback.hidden = false;
    }

    function clearSecret() {
      history.replaceState(null, '', location.pathname);
    }

    if (!token) {
      form.hidden = true;
      lead.hidden = true;
      showError('ลิงก์รีเซ็ตรหัสผ่านไม่ถูกต้องหรือหมดอายุแล้ว กรุณาขอลิงก์ใหม่จากแอป');
      if (location.hash) clearSecret();
    }

    form.addEventListener('submit', async function (event) {
      event.preventDefault();
      if (!token || submit.disabled) return;
      feedback.hidden = true;
      const next = password.value;
      const again = confirmation.value;
      const missing = missingConditions(next);
      if (missing.length) {
        showError('เพิ่มอีก: ' + missing.join(', '));
        return;
      }
      if (new TextEncoder().encode(next).length > 72) {
        showError('รหัสผ่านยาวเกินไป กรุณาใช้รหัสผ่านที่สั้นลง');
        return;
      }
      if (next !== again) {
        showError('รหัสผ่านทั้งสองช่องไม่ตรงกัน');
        return;
      }
      submit.disabled = true;
      try {
        const response = await fetch('/api/auth/reset-password', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
          body: JSON.stringify({ token: token, password: next })
        });
        const body = await response.json().catch(function () { return {}; });
        const message = body && typeof body.message === 'string'
          ? body.message
          : 'ไม่สามารถตั้งรหัสผ่านได้ กรุณาลองใหม่';
        if (response.ok) {
          password.value = '';
          confirmation.value = '';
          clearSecret();
          form.hidden = true;
          lead.hidden = true;
          done.hidden = false;
          return;
        }
        if (response.status === 409 || Array.isArray(body.message)) {
          showError(Array.isArray(body.message) ? body.message.join(' ') : message);
          return;
        }
        if (response.status === 429) {
          const wait = Number(response.headers.get('Retry-After'));
          showError(Number.isFinite(wait) && wait > 0
            ? 'ส่งคำขอมากเกินไป กรุณารอ ' + wait + ' วินาทีแล้วลองใหม่'
            : message);
          return;
        }
        form.hidden = true;
        lead.hidden = true;
        clearSecret();
        showError('ลิงก์รีเซ็ตรหัสผ่านไม่ถูกต้องหรือหมดอายุแล้ว กรุณาขอลิงก์ใหม่จากแอป');
      } catch {
        showError('ไม่สามารถติดต่อเซิร์ฟเวอร์ได้ กรุณาลองใหม่');
      } finally {
        submit.disabled = false;
      }
    });
  </script>
</body>
</html>`;
}
