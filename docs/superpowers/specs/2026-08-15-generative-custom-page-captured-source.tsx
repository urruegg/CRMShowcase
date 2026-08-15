// Captured 2026-08-15 from the "Code" tab of the AI-generated ("Describe your
// page") Custom Page created for the Advisor Cockpit app in CRM Showcase - DEV
// (environment 36c1c7c2-e090-e6a4-96e1-dd02ae894e0e, crmshow_Sales solution).
// Prompt used: "advisorcockpitpage blank to be ready for github copilot to add
// the PCF Control advisorcockpit".
//
// Preserved as primary evidence for the "Approach B" research question raised
// in docs/superpowers/specs/2026-08-15-solution-versioning-and-mda-app-live-resolution-design.md
// -- i.e. whether a Custom Page's content can be authored/deployed as source
// (not just assembled via the Studio's Insert-component picker). NOT yet
// verified whether this "Code" view is a two-way editable/exportable source
// format or a read-only generated preview -- that remains the open question.
//
// Notable observations:
// - Plain functional React component using @fluentui/react-components (the
//   same Fluent v9 library this repo's own PCF controls already use).
// - Uses Xrm.Utility.getGlobalContext() for language/RTL detection -- genuine
//   model-driven-app client API integration, not a sandboxed preview.
// - Uses a `dataApi.retrieveRow(...)` call (a code-custom-page-specific data
//   API, distinct from a PCF control's own context.webAPI).
// - The AI correctly left a blank content area for the PCF control rather
//   than inventing unrelated business logic, per the prompt's intent.

import React from "react";
import { Text, makeStyles, mergeClasses, tokens } from "@fluentui/react-components";

// Language map (module-level constant)
const langMap: Record<number, { code: string; name: string; isRtl: boolean }> = {
  1033: { code: "en-US", name: "English (United States)", isRtl: false },
  1031: { code: "de-DE", name: "German (Germany)", isRtl: false },
  1036: { code: "fr-FR", name: "French (France)", isRtl: false },
  1040: { code: "it-IT", name: "Italian (Italy)", isRtl: false },
};

// Translations dictionary (module-level constant)
const translations: Record<string, Record<string, string>> = {
  "en-US": {
    title: "Advisor Cockpit Page",
    description: "This page is ready for GitHub Copilot to add the PCF Control advisorcockpit.",
  },
  "de-DE": {
    title: "Berater Cockpit Seite",
    description: "Diese Seite ist bereit für GitHub Copilot, um das PCF Control advisorcockpit hinzuzufügen.",
  },
  "fr-FR": {
    title: "Page Cockpit Conseiller",
    description: "Cette page est prête pour que GitHub Copilot ajoute le contrôle PCF advisorcockpit.",
  },
  "it-IT": {
    title: "Pagina Cockpit Consulente",
    description: "Questa pagina è pronta per GitHub Copilot per aggiungere il controllo PCF advisorcockpit.",
  },
};

// Styling
const useStyles = makeStyles({
  root: {
    flexGrow: 1,
    alignSelf: "stretch",
    width: "100%",
    height: "100%",
    minHeight: 0,
    minWidth: 0,
    boxSizing: "border-box",
    display: "flex",
    flexDirection: "column",
    backgroundColor: tokens.colorNeutralBackground1,
    padding: tokens.spacingVerticalXL,
    gap: tokens.spacingVerticalL,
  },
  header: {
    textAlign: "start",
    marginBottom: tokens.spacingVerticalL,
  },
  description: {
    color: tokens.colorNeutralForeground2,
    fontSize: tokens.fontSizeBase400,
    marginBottom: tokens.spacingVerticalL,
  },
  content: {
    flex: 1,
    minHeight: 0,
    minWidth: 0,
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: tokens.colorNeutralBackground2,
    borderRadius: tokens.borderRadiusLarge,
    boxShadow: tokens.shadow4,
    // Blank content area for PCF control
  },
});

const GeneratedComponent = () => {
  // Language detection
  const language = React.useMemo(() => {
    const uiLanguageId =
      (typeof Xrm !== "undefined" &&
        Xrm.Utility?.getGlobalContext()?.userSettings?.languageId) ||
      1033;
    return langMap[uiLanguageId]?.code || "en-US";
  }, []);

  // RTL detection
  const isRTL = React.useMemo(() => {
    const uiLanguageId =
      (typeof Xrm !== "undefined" &&
        Xrm.Utility?.getGlobalContext()?.userSettings?.languageId) ||
      1033;
    return langMap[uiLanguageId]?.isRtl || false;
  }, []);

  // Translation helper
  const t = (key: string): string =>
    translations[language]?.[key] || translations["en-US"]?.[key] || key;

  // User settings fetch (for future formatting needs)
  const [userSettings, setUserSettings] = React.useState<any>(null);
  React.useEffect(() => {
    const fetchUserSettings = async () => {
      try {
        const currentUserId =
          (typeof Xrm !== "undefined" &&
            Xrm.Utility?.getGlobalContext()?.userSettings?.userId)
            ?.replace("{", "")
            .replace("}", "");
        if (!currentUserId) return;
        // @ts-ignore dataApi is not available in blank page, but hook is ready for future use
        if (typeof dataApi !== "undefined" && dataApi?.retrieveRow) {
          const settings = await dataApi.retrieveRow("usersettings", {
            id: currentUserId,
            select: [
              "uilanguageid",
              "localeid",
              "decimalsymbol",
              "numberseparator",
              "currencysymbol",
              "dateformatstring",
              "dateseparator",
            ],
          });
          setUserSettings(settings);
        }
      } catch {
        // Ignore errors in blank page
      }
    };
    fetchUserSettings();
  }, []);

  const styles = useStyles();

  return (
    <div
      dir={isRTL ? "rtl" : "ltr"}
      style={{ direction: isRTL ? "rtl" : "ltr", height: "100%", width: "100%" }}
      className={styles.root}
    >
      <header className={styles.header}>
        <Text as="h1" size={700} weight="semibold" block>
          {t("title")}
        </Text>
        <Text as="p" className={styles.description} block>
          {t("description")}
        </Text>
      </header>
      <main className={styles.content} aria-label={t("title")}>
        {/* Blank content area for PCF Control advisorcockpit */}
      </main>
    </div>
  );
};

export default GeneratedComponent;
