import Foundation

enum CSS {
    // @import url("http://localhost:50082/static/fonts.css");
    static let baseCSS: String = """
    @import url("http://localhost:50082/static/fonts.css");

    :root {
      /* Color */
      --text-color: #222222;
      --surface: #c0c0c0;
      --button-highlight: #ffffff;
      --button-face: #dfdfdf;
      --button-shadow: #808080;
      --window-frame: #0a0a0a;
      --dialog-blue: #000080;
      --dialog-blue-light: #1084d0;
      --dialog-gray: #808080;
      --dialog-gray-light: #b5b5b5;
      --link-blue: #0000ff;

      /* Spacing */
      --element-spacing: 8px;
      --grouped-button-spacing: 4px;
      --grouped-element-spacing: 6px;
      --radio-width: 12px;
      --checkbox-width: 13px;
      --radio-label-spacing: 6px;
      --range-track-height: 4px;
      --range-spacing: 10px;

      /* Some detailed computations for radio buttons and checkboxes */
      --radio-total-width-precalc: var(--radio-width) + var(--radio-label-spacing);
      --radio-total-width: calc(var(--radio-total-width-precalc));
      --radio-left: calc(-1 * var(--radio-total-width-precalc));
      --radio-dot-width: 4px;
      --radio-dot-top: calc(var(--radio-width) / 2 - var(--radio-dot-width) / 2);
      --radio-dot-left: calc(
        -1 * (var(--radio-total-width-precalc)) + var(--radio-width) / 2 - var(
            --radio-dot-width
          ) / 2
      );

      --checkbox-total-width-precalc: var(--checkbox-width) +
        var(--radio-label-spacing);
      --checkbox-total-width: calc(var(--checkbox-total-width-precalc));
      --checkbox-left: calc(-1 * var(--checkbox-total-width-precalc));
      --checkmark-width: 7px;
      --checkmark-left: 3px;

      /* Borders */
      --border-width: 1px;
      --border-raised-outer: inset -1px -1px var(--window-frame),
        inset 1px 1px var(--button-highlight);
      --border-raised-inner: inset -2px -2px var(--button-shadow),
        inset 2px 2px var(--button-face);
      --border-sunken-outer: inset -1px -1px var(--button-highlight),
        inset 1px 1px var(--window-frame);
      --border-sunken-inner: inset -2px -2px var(--button-face),
        inset 2px 2px var(--button-shadow);
      --default-button-border-raised-outer: inset -2px -2px var(--window-frame), inset 1px 1px var(--window-frame);
      --default-button-border-raised-inner: inset 2px 2px var(--button-highlight), inset -3px -3px var(--button-shadow), inset 3px 3px var(--button-face);
      --default-button-border-sunken-outer: inset 2px 2px var(--window-frame), inset -1px -1px var(--window-frame);
      --default-button-border-sunken-inner: inset -2px -2px var(--button-highlight), inset 3px 3px var(--button-shadow), inset -3px -3px var(--button-face);


      /* Window borders flip button-face and button-highlight */
      --border-window-outer: inset -1px -1px var(--window-frame),
        inset 1px 1px var(--button-face);
      --border-window-inner: inset -2px -2px var(--button-shadow),
        inset 2px 2px var(--button-highlight);

      /* Field borders (checkbox, input, etc) flip window-frame and button-shadow */
      --border-field: inset -1px -1px var(--button-highlight),
        inset 1px 1px var(--button-shadow), inset -2px -2px var(--button-face),
        inset 2px 2px var(--window-frame);
    }

    body {
        margin: 0;
        padding: 0;
        background-color: var(--surface);
        color: var(--text-color);
    }

    button, body, input, textarea {
        -webkit-font-smoothing: none;
        font-family: "RetroFont";
        font-size: 12px;
    }

    button,
    input[type="submit"],
    input[type="reset"] {
      box-sizing: border-box;
      border: none;
      color: transparent;
      text-shadow: 0 0 var(--text-color);
      background: var(--surface);
      box-shadow: var(--border-raised-outer), var(--border-raised-inner);
      border-radius: 0;

      min-width: 75px;
      min-height: 23px;
      padding: 0 12px;

      outline: none;
    }

    button.default,
    input[type="submit"].default,
    input[type="reset"].default {
      box-shadow: var(--default-button-border-raised-outer), var(--default-button-border-raised-inner);
    }

    .vertical-bar {
      width: 4px;
      height: 20px;
      background: #c0c0c0;
      box-shadow: var(--border-raised-outer), var(--border-raised-inner);
    }

    button:not(:disabled):active,
    input[type="submit"]:not(:disabled):active,
    input[type="reset"]:not(:disabled):active {
      box-shadow: var(--border-sunken-outer), var(--border-sunken-inner);
      text-shadow: 1px 1px var(--text-color);
    }

    button.default:not(:disabled):active,
    input[type="submit"].default:not(:disabled):active,
    input[type="reset"].default:not(:disabled):active {
      box-shadow: var(--default-button-border-sunken-outer), var(--default-button-border-sunken-inner);
    }

    button:focus,
    input[type="submit"]:focus,
    input[type="reset"]:focus {
      outline: 1px dotted #000000;
      outline-offset: -4px;
    }

    button:disabled,
    input[type="submit"]:disabled,
    input[type="reset"]:disabled,
    :disabled + label {
      text-shadow: 1px 1px 0 var(--button-highlight);
    }

    .status-bar {
      margin: 0px 1px;
      display: flex;
      gap: 1px;
    }

    .status-bar-field {
      box-shadow: inset -1px -1px #dfdfdf, inset 1px 1px #808080;
      flex-grow: 1;
      padding: 2px 3px;
      margin: 0;
    }

    input[type="text"],
    input[type="password"],
    input[type="email"],
    input[type="tel"],
    input[type="number"],
    input[type="search"],
    select,
    textarea {
      padding: 3px 4px;
      border: none;
      box-shadow: var(--border-field);
      background-color: var(--button-highlight);
      box-sizing: border-box;
      -webkit-appearance: none;
      -moz-appearance: none;
      appearance: none;
      border-radius: 0;
    }

    input[type="text"],
    input[type="password"],
    input[type="email"],
    input[type="tel"],
    input[type="search"],
    select {
      height: 21px;
    }

    .sunken-panel {
      box-sizing: border-box;
      border: 2px groove transparent;
      border-image: svg-load("./icon/sunken-panel-border.svg") 2;
      overflow: auto;
      background-color: #fff;
    }

    table {
      border-collapse: collapse;
      position: relative;
      text-align: left;
      white-space: nowrap;
      background-color: #fff;
    }
    """
}
