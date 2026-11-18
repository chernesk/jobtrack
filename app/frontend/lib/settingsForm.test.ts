import type { Settings } from "../types";
import { environmentHint, toSettingsFormData } from "./settingsForm";

const settings: Settings = {
  auto_refresh_enabled: true,
  auto_refresh_seconds: 30,
  notifications_enabled: true,
  notify_when_nothing_due: false,
  hide_names: false,
  ntfy_url: null,
  ntfy_topic: "my-topic",
  app_url: null,
  ntfy_token_saved: true,
  from_environment: {
    ntfy_url: false,
    ntfy_topic: false,
    ntfy_token: false,
    app_url: false,
    hide_names: false,
  },
};

describe("toSettingsFormData", () => {
  it("turns unset text into empty strings and never preloads the token", () => {
    expect(toSettingsFormData(settings)).toEqual({
      auto_refresh_enabled: true,
      auto_refresh_seconds: 30,
      notifications_enabled: true,
      notify_when_nothing_due: false,
      hide_names: false,
      ntfy_url: "",
      ntfy_topic: "my-topic",
      ntfy_token: "",
      clear_ntfy_token: false,
      app_url: "",
    });
  });
});

describe("environmentHint", () => {
  it("names the variable only when the environment supplies the value", () => {
    expect(environmentHint(true, "NTFY_TOPIC")).toBe(
      "Blank: using NTFY_TOPIC from the server environment.",
    );
    expect(environmentHint(false, "NTFY_TOPIC")).toBeUndefined();
  });
});
