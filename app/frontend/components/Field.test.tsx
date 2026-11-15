import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { useState } from "react";

import Field from "./Field";

function CompanyField({ error }: { error?: string }) {
  const [value, setValue] = useState("");
  return (
    <Field label="Company" error={error}>
      {(control) => (
        <input {...control} value={value} onChange={(event) => setValue(event.target.value)} />
      )}
    </Field>
  );
}

describe("Field", () => {
  it("connects the label to the control", async () => {
    render(<CompanyField />);

    await userEvent.type(screen.getByLabelText("Company"), "Acme Logistics");

    expect(screen.getByLabelText("Company")).toHaveValue("Acme Logistics");
  });

  it("shows no error message and no invalid state by default", () => {
    render(<CompanyField />);

    expect(screen.queryByRole("alert")).not.toBeInTheDocument();
    expect(screen.getByLabelText("Company")).not.toBeInvalid();
  });

  it("shows the error next to the field and marks it invalid", () => {
    render(<CompanyField error="can't be blank" />);

    expect(screen.getByRole("alert")).toHaveTextContent("can't be blank");
    expect(screen.getByLabelText("Company")).toBeInvalid();
    expect(screen.getByLabelText("Company")).toHaveAccessibleDescription("can't be blank");
  });
});
