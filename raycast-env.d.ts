/// <reference types="@raycast/api">

/* 🚧 🚧 🚧
 * This file is auto-generated from the extension's manifest.
 * Do not modify manually. Instead, update the `package.json` file.
 * 🚧 🚧 🚧 */

/* eslint-disable @typescript-eslint/ban-types */

type ExtensionPreferences = {}

/** Preferences accessible in all the extension's commands */
declare type Preferences = ExtensionPreferences

declare namespace Preferences {
  /** Preferences accessible in the `where-is-my-cursor` command */
  export type WhereIsMyCursor = ExtensionPreferences & {}
  /** Preferences accessible in the `off` command */
  export type Off = ExtensionPreferences & {}
  /** Preferences accessible in the `simple-mode` command */
  export type SimpleMode = ExtensionPreferences & {}
  /** Preferences accessible in the `presentation-mode` command */
  export type PresentationMode = ExtensionPreferences & {}
  /** Preferences accessible in the `custom` command */
  export type Custom = ExtensionPreferences & {}
}

declare namespace Arguments {
  /** Arguments passed to the `where-is-my-cursor` command */
  export type WhereIsMyCursor = {}
  /** Arguments passed to the `off` command */
  export type Off = {}
  /** Arguments passed to the `simple-mode` command */
  export type SimpleMode = {}
  /** Arguments passed to the `presentation-mode` command */
  export type PresentationMode = {}
  /** Arguments passed to the `custom` command */
  export type Custom = {}
}

declare module "swift:*/locatecursor" {
  export function locatecursor(arg1: string, arg2: string, arg3: string): Promise<void>;

  export class SwiftError extends Error {
    stderr: string;
    stdout: string;
  }
}