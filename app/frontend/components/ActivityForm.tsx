import { useForm } from "@inertiajs/react";
import type { FormEvent } from "react";

import { todayISO } from "../lib/dates";
import { ACTIVITY_KIND_LABELS } from "../lib/labels";
import { ACTIVITY_KINDS, type ActivityFormData, type ActivityKind } from "../types";
import Button from "./Button";
import Field from "./Field";

interface ActivityFormProps {
  opportunityId: number;
}

export default function ActivityForm({ opportunityId }: ActivityFormProps) {
  const form = useForm<ActivityFormData>({ kind: "email", occurred_on: todayISO(), body: "" });
  const { data, setData, errors } = form;

  // Rails expects params nested under `activity`.
  form.transform((values) => ({ activity: values }));

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    if (!data.body.trim()) {
      form.setError("body", "Add a note about what happened");
      return;
    }

    form.clearErrors();
    form.post(`/opportunities/${opportunityId}/activities`, {
      // Stay where you are on the page, and clear only the text so the date and
      // kind are ready for the next entry.
      preserveScroll: true,
      onSuccess: () => form.reset("body"),
    });
  }

  return (
    <form onSubmit={submit} noValidate className="space-y-4">
      <div className="grid gap-4 sm:grid-cols-2">
        <Field label="Activity type" error={errors.kind}>
          {(control) => (
            <select
              {...control}
              value={data.kind}
              onChange={(event) => setData("kind", event.target.value as ActivityKind)}
            >
              {ACTIVITY_KINDS.map((kind) => (
                <option key={kind} value={kind}>
                  {ACTIVITY_KIND_LABELS[kind]}
                </option>
              ))}
            </select>
          )}
        </Field>
        <Field label="Date" error={errors.occurred_on}>
          {(control) => (
            <input
              {...control}
              type="date"
              required
              value={data.occurred_on}
              onChange={(event) => setData("occurred_on", event.target.value)}
            />
          )}
        </Field>
      </div>
      <Field label="What happened" error={errors.body}>
        {(control) => (
          <textarea
            {...control}
            rows={3}
            required
            value={data.body}
            onChange={(event) => setData("body", event.target.value)}
          />
        )}
      </Field>
      <Button type="submit" disabled={form.processing}>
        Add activity
      </Button>
    </form>
  );
}
