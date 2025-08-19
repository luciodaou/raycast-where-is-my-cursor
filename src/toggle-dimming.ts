import { exec } from "child_process";
import {
  showToast,
  Toast,
  closeMainWindow,
  PopToRootType,
  environment,
} from "@raycast/api";
import { join } from "path";

const helperPath = join(environment.assetsPath, "LocateCursor");

export default function main() {
  const command = `"${helperPath}" 0`;

  exec(command, (error) => {
    if (error) {
      showToast({
        style: Toast.Style.Failure,
        title: "Failed to toggle dimming",
        message: error.message,
      });
    }
  });
  closeMainWindow({
    clearRootSearch: true,
    popToRootType: PopToRootType.Immediate,
  });
}
