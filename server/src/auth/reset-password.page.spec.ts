import { runInNewContext } from 'node:vm';
import { renderResetPasswordPage } from './reset-password.page.js';

function page() {
  const elements = new Map<string, { value: string; hidden: boolean; disabled: boolean; textContent: string; listeners: Record<string, (event: { preventDefault: () => void }) => Promise<void> | void>; addEventListener: (name: string, callback: (event: { preventDefault: () => void }) => Promise<void> | void) => void }>();
  for (const id of ['reset-form', 'lead', 'feedback', 'done', 'submit', 'password', 'confirmation', 'requirements']) {
    elements.set(id, {
      value: '', hidden: false, disabled: false, textContent: '', listeners: {},
      addEventListener(name, callback) { this.listeners[name] = callback; },
    });
  }
  const fetch = vi.fn().mockResolvedValue({ ok: true, json: async () => ({}) });
  const history = { replaceState: vi.fn() };
  const html = renderResetPasswordPage('a'.repeat(22));
  const script = /<script nonce="[^"]+">([\s\S]*?)<\/script>/.exec(html)![1];
  runInNewContext(script, {
    document: { getElementById: (id: string) => elements.get(id) },
    location: { hash: '#token=' + 'a'.repeat(64), pathname: '/reset-password' },
    history, fetch, TextEncoder,
  });
  return { elements, fetch, history, html };
}

describe('API reset password page validation', () => {
  it.each(['Aa1!abc', 'lowercase1!', 'UPPERCASE1!', 'NoNumbers!', 'NoSymbols123', 'NoSymbols123🔐', 'Aa1!' + 'ก'.repeat(23)])('blocks invalid password without submitting or clearing the token: %s', async (password) => {
    const view = page();
    view.elements.get('password')!.value = password;
    view.elements.get('confirmation')!.value = password;
    await view.elements.get('reset-form')!.listeners.submit({ preventDefault() {} });
    expect(view.fetch).not.toHaveBeenCalled();
    expect(view.history.replaceState).not.toHaveBeenCalled();
    expect(view.elements.get('feedback')!.hidden).toBe(false);
  });

  it('shows compact guidance and missing requirements only while typing', () => {
    const view = page();
    expect(view.html).toContain('อย่างน้อย 8 ตัว มี A–Z, a–z, ตัวเลข และสัญลักษณ์');
    const password = view.elements.get('password')!;
    password.value = 'lowercase1!';
    password.listeners.input({ preventDefault() {} });
    expect(view.elements.get('requirements')!.textContent).toBe('เพิ่มอีก: ตัวพิมพ์ใหญ่ A–Z');
    password.value = 'Aa1!abcd';
    password.listeners.input({ preventDefault() {} });
    expect(view.elements.get('requirements')!.hidden).toBe(true);
  });

  it('blocks mismatch then accepts 72 UTF-8 bytes and clears token only on success', async () => {
    const view = page();
    const password = 'Aa1!' + 'ก'.repeat(22) + 'ab';
    view.elements.get('password')!.value = password;
    view.elements.get('confirmation')!.value = 'different';
    await view.elements.get('reset-form')!.listeners.submit({ preventDefault() {} });
    expect(view.fetch).not.toHaveBeenCalled();
    view.elements.get('confirmation')!.value = password;
    await view.elements.get('reset-form')!.listeners.submit({ preventDefault() {} });
    expect(view.fetch).toHaveBeenCalledOnce();
    expect(view.history.replaceState).toHaveBeenCalledOnce();
  });
});
