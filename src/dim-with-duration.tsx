import { Form, ActionPanel, Action, showToast, Toast, environment } from "@raycast/api";
import { exec } from "child_process";
import { join } from "path";

const helperPath = join(environment.assetsPath, "LocateCursor");

interface FormValues {
  duration: string;
}

export default function Command() {
  function handleSubmit(values: FormValues) {
    const duration = parseInt(values.duration, 10);
    if (isNaN(duration) || duration <= 0) {
      showToast({
        style: Toast.Style.Failure,
        title: "Invalid Duration",
        message: "Please enter a positive number for the duration.",
      });
      return;
    }

    const command = `${helperPath} on ${duration}`;

    exec(command, (error) => {
      if (error) {
        showToast({
          style: Toast.Style.Failure,
          title: "Failed to start dimming",
          message: error.message,
        });
      } else {
        showToast({
          style: Toast.Style.Success,
          title: `Dimming started for ${duration} seconds`,
        });
      }
    });
  }

  return (
    <Form
      actions={
        <ActionPanel>
          <Action.SubmitForm title="Start Dimming" onSubmit={handleSubmit} />
        </ActionPanel>
      }
    >
      <Form.TextField
        id="duration"
        title="Duration"
        placeholder="Enter duration in seconds"
        defaultValue="10"
      />
    </Form>
  );
}
