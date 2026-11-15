import { PAY_UNIT_LABELS } from "../lib/labels";
import type { PayUnit } from "../types";

const currency = new Intl.NumberFormat("en-US", {
  style: "currency",
  currency: "USD",
  maximumFractionDigits: 0,
});

interface PayRangeProps {
  min: number | null;
  max: number | null;
  unit: PayUnit | null;
}

// Returns null when neither bound is set. Each branch below narrows the types
// (`min`/`max` are `number` inside it), so no type assertions are needed.
function formatAmount(min: number | null, max: number | null): string | null {
  if (min !== null && max !== null) {
    return min === max ? currency.format(min) : `${currency.format(min)} – ${currency.format(max)}`;
  }
  if (min !== null) return `${currency.format(min)}+`;
  if (max !== null) return `Up to ${currency.format(max)}`;
  return null;
}

export function formatPayRange({ min, max, unit }: PayRangeProps): string {
  const amount = formatAmount(min, max);
  if (amount === null) return "Pay not listed";
  return unit ? `${amount} / ${PAY_UNIT_LABELS[unit]}` : amount;
}

export default function PayRange(props: PayRangeProps) {
  const listed = props.min !== null || props.max !== null;
  return <span className={listed ? "" : "text-slate-400"}>{formatPayRange(props)}</span>;
}
