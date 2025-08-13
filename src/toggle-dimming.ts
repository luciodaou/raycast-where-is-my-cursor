import { exec } from "child_process";
import { showToast, Toast, environment } from "@raycast/api";
import { join } from "path";
import * as fs from "fs";

const pidFilePath = "/tmp/LocateCursor.pid";
const helperPath = join(environment.assetsPath, "LocateCursor");

export default async function main() {
  let isRunning = false;
  try {
    fs.accessSync(pidFilePath, fs.constants.F_OK);
    isRunning = true;
  } catch (e) {
    // File does not exist
    isRunning = false;
  }


  const command = isRunning ? `${helperPath} off` : `${helperPath} on`;

  exec(command, (error) => {
    if (error) {
      showToast({
        style: Toast.Style.Failure,
        title: "Failed to toggle dimming",
        message: error.message,
      });
    } else {
      showToast({
        style: Toast.Style.Success,
        title: `Dimming turned ${isRunning ? "off" : "on"}`,
      });
    }
  });
}
