import { router, useForm } from "@inertiajs/react";
import type { FormEvent, ReactNode } from "react";

import Button from "../../components/Button";
import Field from "../../components/Field";
import Layout from "../../components/Layout";
import { environmentHint, toSettingsFormData } from "../../lib/settingsForm";
import { REFRESH_CHOICES, type SettingsEditProps } from "../../types";

interface ToggleProps {
  label: string;
  hint?: string | undefined;
  checked: boolean;
  onChange: (checked: boolean) => void;
}

function Toggle({ label, hint, checked, onChange }: ToggleProps) {
  return (
    <label className="flex items-start gap-3 text-sm text-slate-700 dark:text-slate-300">
      <input
        type="checkbox"
        className="mt-0.5"
        checked={checked}
        onChange={(event) => onChange(event.target.checked)}
      />
      <span>
        {label}
        {hint && <span className="block text-slate-500 dark:text-slate-400">{hint}</span>}
      </span>
    </label>
  );
}

function Section({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className="space-y-4">
      <h2 className="text-base font-semibold">{title}</h2>
      {children}
    </section>
  );
}

function Hint({ text }: { text: string | undefined }) {
  return text ? <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">{text}</p> : null;
}

export default function Edit({ settings }: SettingsEditProps) {
  const form = useForm(toSettingsFormData(settings));
  const { data, setData, errors } = form;
  const env = settings.from_environment;

  // Rails expects params nested under `setting` (params.expect(setting: ...)).
  form.transform((values) => ({ setting: values }));

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    form.patch("/settings", {
      preserveScroll: true,
      // Never keep a typed token in the page after it was sent.
      onSuccess: () => form.setData({ ...data, ntfy_token: "", clear_ntfy_token: false }),
    });
  }

  return (
    <Layout>
      <h1 className="text-2xl font-semibold">Settings</h1>

      <form onSubmit={submit} className="mt-6 max-w-xl space-y-8" noValidate>
        <Section title="Live updates">
          <Toggle
            label="Refresh open pages automatically"
            hint="Pages re-check for changes (for example from your AI assistant) while the tab is visible."
            checked={data.auto_refresh_enabled}
            onChange={(checked) => setData("auto_refresh_enabled", checked)}
          />
          <Field label="Refresh every" error={errors.auto_refresh_seconds}>
            {(control) => (
              <select
                {...control}
                value={data.auto_refresh_seconds}
                disabled={!data.auto_refresh_enabled}
                onChange={(event) => setData("auto_refresh_seconds", Number(event.target.value))}
              >
                {REFRESH_CHOICES.map((seconds) => (
                  <option key={seconds} value={seconds}>
                    {seconds} seconds
                  </option>
                ))}
              </select>
            )}
          </Field>
        </Section>

        <Section title="Follow-up notifications">
          <p className="text-sm text-slate-500 dark:text-slate-400">
            A push through{" "}
            <a
              href="https://ntfy.sh"
              target="_blank"
              rel="noopener noreferrer"
              className="underline"
            >
              ntfy
            </a>{" "}
            at 7am Eastern listing follow-ups that are due. It needs a topic to send anything.
          </p>
          <Toggle
            label="Send the daily notification"
            checked={data.notifications_enabled}
            onChange={(checked) => setData("notifications_enabled", checked)}
          />
          <Toggle
            label="Also send a quiet message when nothing is due"
            hint="So you know the check ran."
            checked={data.notify_when_nothing_due}
            onChange={(checked) => setData("notify_when_nothing_due", checked)}
          />
          <Toggle
            label="Leave company names out of the message"
            hint={env.hide_names ? "Also switched on by NTFY_HIDE_NAMES." : "Sends only a count."}
            checked={data.hide_names}
            onChange={(checked) => setData("hide_names", checked)}
          />

          <Field label="Topic" error={errors.ntfy_topic}>
            {(control) => (
              <>
                <input
                  {...control}
                  type="text"
                  value={data.ntfy_topic}
                  autoComplete="off"
                  onChange={(event) => setData("ntfy_topic", event.target.value)}
                />
                <Hint
                  text={
                    environmentHint(env.ntfy_topic && !data.ntfy_topic, "NTFY_TOPIC") ??
                    "Use a long, hard-to-guess name: on ntfy.sh anyone who knows a topic can read it."
                  }
                />
              </>
            )}
          </Field>
          <Field label="ntfy server" error={errors.ntfy_url}>
            {(control) => (
              <>
                <input
                  {...control}
                  type="text"
                  value={data.ntfy_url}
                  placeholder="https://ntfy.sh"
                  autoComplete="off"
                  onChange={(event) => setData("ntfy_url", event.target.value)}
                />
                <Hint text={environmentHint(env.ntfy_url && !data.ntfy_url, "NTFY_URL")} />
              </>
            )}
          </Field>
          <Field label="Access token" error={errors.ntfy_token}>
            {(control) => (
              <>
                <input
                  {...control}
                  type="password"
                  value={data.ntfy_token}
                  placeholder={settings.ntfy_token_saved ? "Saved. Leave blank to keep it." : ""}
                  autoComplete="new-password"
                  onChange={(event) => setData("ntfy_token", event.target.value)}
                />
                <Hint
                  text={
                    settings.ntfy_token_saved
                      ? undefined
                      : environmentHint(env.ntfy_token, "NTFY_TOKEN")
                  }
                />
              </>
            )}
          </Field>
          {settings.ntfy_token_saved && (
            <Toggle
              label="Remove the saved token"
              checked={data.clear_ntfy_token}
              onChange={(checked) => setData("clear_ntfy_token", checked)}
            />
          )}
          <Field label="JobTrack address" error={errors.app_url}>
            {(control) => (
              <>
                <input
                  {...control}
                  type="text"
                  value={data.app_url}
                  placeholder="http://nas.local:3200"
                  autoComplete="off"
                  onChange={(event) => setData("app_url", event.target.value)}
                />
                <Hint
                  text={
                    environmentHint(env.app_url && !data.app_url, "APP_URL") ??
                    "Tapping the notification opens this address."
                  }
                />
              </>
            )}
          </Field>
        </Section>

        <div className="flex items-center gap-3">
          <Button type="submit" disabled={form.processing}>
            Save settings
          </Button>
          <Button variant="secondary" onClick={() => router.post("/settings/test")}>
            Send a test notification
          </Button>
        </div>
        <p className="text-sm text-slate-500 dark:text-slate-400">
          The test uses the saved settings, so save first.
        </p>
      </form>
    </Layout>
  );
}
