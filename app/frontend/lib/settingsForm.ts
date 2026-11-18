import type { Settings, SettingsFormData } from "../types";

// Text fields are strings in the form; a null from Rails ("not set") becomes "".
// The token is never loaded: the field starts empty, and empty means "keep what is saved".
export function toSettingsFormData(settings: Settings): SettingsFormData {
  return {
    auto_refresh_enabled: settings.auto_refresh_enabled,
    auto_refresh_seconds: settings.auto_refresh_seconds,
    notifications_enabled: settings.notifications_enabled,
    notify_when_nothing_due: settings.notify_when_nothing_due,
    hide_names: settings.hide_names,
    ntfy_url: settings.ntfy_url ?? "",
    ntfy_topic: settings.ntfy_topic ?? "",
    ntfy_token: "",
    clear_ntfy_token: false,
    app_url: settings.app_url ?? "",
  };
}

// Under a blank field, say where its value comes from instead.
export function environmentHint(fromEnvironment: boolean, variable: string): string | undefined {
  return fromEnvironment ? `Blank: using ${variable} from the server environment.` : undefined;
}
