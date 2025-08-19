import { exec } from "child_process";
import {
  showToast,
  Toast,
  closeMainWindow,
  PopToRootType,
  environment,
  getPreferenceValues,
} from "@raycast/api";
import { join } from "path";

const helperPath = join(environment.assetsPath, "LocateCursor");

interface Arguments {
  duration?: string;
}

export default function main(props: { arguments: Arguments }) {
  const { duration } = props.arguments;
  const preferences = getPreferenceValues<Preferences>();
  const dimDuration = duration
    ? parseFloat(duration)
    : parseFloat(preferences.dimDuration);

  const command = `"${helperPath}" ${dimDuration}`;

  exec(command, (error) => {
    if (error) {
      showToast({
        style: Toast.Style.Failure,
        title: "Failed to locate cursor",
        message: error.message,
      });
    }
  });
  closeMainWindow({
    clearRootSearch: true,
    popToRootType: PopToRootType.Immediate,
  });
}
