.pragma library
.import "lang/ru.js" as Ru
.import "lang/zh_CN.js" as ZhCN
.import "lang/zh_TW.js" as ZhTW
.import "lang/ja.js" as Ja
.import "lang/ko.js" as Ko
.import "lang/vi.js" as Vi

// Interface translations. I18n.tr("English text") returns the text in the chosen language, or the English text
// itself when there is no translation. The language is Qt.uiLanguage (Settings → General → Language, set by
// YukiBar), or the system locale (LANG, e.g. ja_JP.UTF-8) when that is empty. Bindings that call tr() read
// Qt.uiLanguage, so they update when the language changes.
// To add a language: copy lang/vi.js to lang/<code>.js, translate the values, and add it to `dicts` and `languages` below.

var dicts = { ru: Ru.strings, zh_CN: ZhCN.strings, zh_TW: ZhTW.strings, ja: Ja.strings, ko: Ko.strings, vi: Vi.strings };

// What Settings offers: the code that is saved, the name in its own language, the English name.
var languages = [
    { code: "en",    name: "English",    english: "English" },
    { code: "zh_CN", name: "简体中文",    english: "Chinese (Simplified)" },
    { code: "zh_TW", name: "繁體中文",    english: "Chinese (Traditional)" },
    { code: "ja",    name: "日本語",      english: "Japanese" },
    { code: "ko",    name: "한국어",      english: "Korean" },
    { code: "vi",    name: "Tiếng Việt", english: "Vietnamese" },
    { code: "ru",    name: "Русский",    english: "Russian" }
];

// The dictionary to use: zh_TW / zh_HK / zh_MO / zh-Hant are Traditional Chinese, any other zh is Simplified.
function code() {
    var n = String(Qt.uiLanguage !== "" ? Qt.uiLanguage : (Qt.locale().name || "en")).replace("-", "_");
    var lang = n.split("_")[0];
    if (lang === "zh")
        return /Hant|_TW|_HK|_MO/.test(n) ? "zh_TW" : "zh_CN";
    return lang;
}

function tr(text) {
    var d = dicts[code()];
    if (!d || typeof text !== "string")
        return text;
    var t = d[text];
    return t !== undefined ? t : text;
}

// The locale for day and month names: the chosen language, or the system locale.
function locale() {
    return Qt.uiLanguage !== "" ? Qt.locale(Qt.uiLanguage) : Qt.locale();
}
