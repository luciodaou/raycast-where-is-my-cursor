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
  /** Preferences accessible in the `toggle-dimming` command */
  export type ToggleDimming = ExtensionPreferences & {}
  /** Preferences accessible in the `dim-with-duration` command */
  export type DimWithDuration = ExtensionPreferences & {}
}

declare namespace Arguments {
  /** Arguments passed to the `where-is-my-cursor` command */
  export type WhereIsMyCursor = {}
  /** Arguments passed to the `toggle-dimming` command */
  export type ToggleDimming = {}
  /** Arguments passed to the `dim-with-duration` command */
  export type DimWithDuration = {}
}

