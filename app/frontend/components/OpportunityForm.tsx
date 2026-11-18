import { Link, useForm } from "@inertiajs/react";
import type { FormEvent } from "react";

import {
  APPLICATION_CHANNEL_LABELS,
  CLOSED_REASON_LABELS,
  KIND_LABELS,
  PAY_UNIT_LABELS,
  SOURCE_LABELS,
  STATUS_LABELS,
} from "../lib/labels";
import { requiredErrors, toFormData } from "../lib/opportunityForm";
import {
  APPLICATION_CHANNELS,
  CLOSED_REASONS,
  KINDS,
  PAY_UNITS,
  SOURCES,
  STATUSES,
  type ApplicationChannel,
  type ClosedReason,
  type Kind,
  type Opportunity,
  type OpportunityFormData,
  type PayUnit,
  type Source,
  type Status,
} from "../types";
import Button from "./Button";
import Field from "./Field";

interface OpportunityFormProps {
  // Present when editing; absent for a new record.
  opportunity?: Opportunity;
}

export default function OpportunityForm({ opportunity }: OpportunityFormProps) {
  const form = useForm<OpportunityFormData>(toFormData(opportunity));
  const { data, setData, errors } = form;

  // Rails expects params nested under `opportunity` (params.expect(opportunity: ...)).
  form.transform((values) => ({ opportunity: values }));

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    // Client-side check first: instant feedback, no request. The server repeats
    // every validation, so this is a convenience, not a security boundary.
    const missing = requiredErrors(data);
    if (Object.keys(missing).length > 0) {
      form.setError(missing);
      return;
    }

    form.clearErrors();
    if (opportunity) {
      form.patch(`/opportunities/${opportunity.id}`);
    } else {
      form.post("/opportunities");
    }
  }

  return (
    // noValidate: we show our own messages next to the fields instead of the
    // browser's pop-ups, so client and server errors look the same.
    <form onSubmit={submit} noValidate className="max-w-2xl space-y-5">
      <Field label="Company" error={errors.company}>
        {(control) => (
          <input
            {...control}
            required
            value={data.company}
            onChange={(event) => setData("company", event.target.value)}
          />
        )}
      </Field>

      <Field label="Role" error={errors.role}>
        {(control) => (
          <input
            {...control}
            required
            value={data.role}
            onChange={(event) => setData("role", event.target.value)}
          />
        )}
      </Field>

      <div className="grid gap-5 sm:grid-cols-3">
        <Field label="Status" error={errors.status}>
          {(control) => (
            <select
              {...control}
              value={data.status}
              onChange={(event) => setData("status", event.target.value as Status)}
            >
              {STATUSES.map((status) => (
                <option key={status} value={status}>
                  {STATUS_LABELS[status]}
                </option>
              ))}
            </select>
          )}
        </Field>
        <Field label="Type" error={errors.kind}>
          {(control) => (
            <select
              {...control}
              value={data.kind}
              onChange={(event) => setData("kind", event.target.value as Kind | "")}
            >
              <option value="">Not set</option>
              {KINDS.map((kind) => (
                <option key={kind} value={kind}>
                  {KIND_LABELS[kind]}
                </option>
              ))}
            </select>
          )}
        </Field>
        <Field label="Source" error={errors.source}>
          {(control) => (
            <select
              {...control}
              value={data.source}
              onChange={(event) => setData("source", event.target.value as Source | "")}
            >
              <option value="">Not set</option>
              {SOURCES.map((source) => (
                <option key={source} value={source}>
                  {SOURCE_LABELS[source]}
                </option>
              ))}
            </select>
          )}
        </Field>
      </div>

      {data.status === "closed" && (
        <Field label="Why did it close?" error={errors.closed_reason}>
          {(control) => (
            <select
              {...control}
              value={data.closed_reason}
              onChange={(event) =>
                setData("closed_reason", event.target.value as ClosedReason | "")
              }
            >
              <option value="">Not set</option>
              {CLOSED_REASONS.map((reason) => (
                <option key={reason} value={reason}>
                  {CLOSED_REASON_LABELS[reason]}
                </option>
              ))}
            </select>
          )}
        </Field>
      )}

      <div className="grid gap-5 sm:grid-cols-3">
        <Field label="Minimum pay" error={errors.pay_min}>
          {(control) => (
            <input
              {...control}
              type="number"
              min={0}
              inputMode="numeric"
              value={data.pay_min}
              onChange={(event) => setData("pay_min", event.target.value)}
            />
          )}
        </Field>
        <Field label="Maximum pay" error={errors.pay_max}>
          {(control) => (
            <input
              {...control}
              type="number"
              min={0}
              inputMode="numeric"
              value={data.pay_max}
              onChange={(event) => setData("pay_max", event.target.value)}
            />
          )}
        </Field>
        <Field label="Pay unit" error={errors.pay_unit}>
          {(control) => (
            <select
              {...control}
              value={data.pay_unit}
              onChange={(event) => setData("pay_unit", event.target.value as PayUnit | "")}
            >
              <option value="">Not set</option>
              {PAY_UNITS.map((unit) => (
                <option key={unit} value={unit}>
                  Per {PAY_UNIT_LABELS[unit]}
                </option>
              ))}
            </select>
          )}
        </Field>
      </div>

      <div className="grid gap-5 sm:grid-cols-3">
        <Field label="Applied via" error={errors.application_channel}>
          {(control) => (
            <select
              {...control}
              value={data.application_channel}
              onChange={(event) =>
                setData("application_channel", event.target.value as ApplicationChannel | "")
              }
            >
              <option value="">Not set</option>
              {APPLICATION_CHANNELS.map((channel) => (
                <option key={channel} value={channel}>
                  {APPLICATION_CHANNEL_LABELS[channel]}
                </option>
              ))}
            </select>
          )}
        </Field>
        <Field label="Resume version" error={errors.resume_version}>
          {(control) => (
            <input
              {...control}
              value={data.resume_version}
              onChange={(event) => setData("resume_version", event.target.value)}
            />
          )}
        </Field>
        <Field label="Contact person" error={errors.contact_name}>
          {(control) => (
            <input
              {...control}
              value={data.contact_name}
              onChange={(event) => setData("contact_name", event.target.value)}
            />
          )}
        </Field>
      </div>

      <Field label="Posting URL" error={errors.url}>
        {(control) => (
          <input
            {...control}
            type="url"
            value={data.url}
            onChange={(event) => setData("url", event.target.value)}
          />
        )}
      </Field>

      <div className="grid gap-5 sm:grid-cols-2">
        <Field label="Posting ID" error={errors.external_id}>
          {(control) => (
            <input
              {...control}
              placeholder="The job board's id, e.g. 42472"
              value={data.external_id}
              onChange={(event) => setData("external_id", event.target.value)}
            />
          )}
        </Field>
        <Field label="Posting last verified" error={errors.last_verified_on}>
          {(control) => (
            <input
              {...control}
              type="date"
              value={data.last_verified_on}
              onChange={(event) => setData("last_verified_on", event.target.value)}
            />
          )}
        </Field>
      </div>

      <div className="grid gap-5 sm:grid-cols-2">
        <Field label="Contacted on" error={errors.contacted_on}>
          {(control) => (
            <input
              {...control}
              type="date"
              value={data.contacted_on}
              onChange={(event) => setData("contacted_on", event.target.value)}
            />
          )}
        </Field>
        <Field label="Follow up on" error={errors.follow_up_on}>
          {(control) => (
            <input
              {...control}
              type="date"
              value={data.follow_up_on}
              onChange={(event) => setData("follow_up_on", event.target.value)}
            />
          )}
        </Field>
      </div>

      <Field label="Notes" error={errors.notes}>
        {(control) => (
          <textarea
            {...control}
            rows={4}
            value={data.notes}
            onChange={(event) => setData("notes", event.target.value)}
          />
        )}
      </Field>

      <div className="flex items-center gap-3">
        <Button type="submit" disabled={form.processing}>
          {opportunity ? "Save changes" : "Add opportunity"}
        </Button>
        <Link
          href="/opportunities"
          className="text-sm text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-slate-100"
        >
          Cancel
        </Link>
      </div>
    </form>
  );
}
