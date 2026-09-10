import { SettingsSection, SettingsSectionModel } from '../../../models/ShellModels';
import { AppPreferencesModel, NimboFont, NimboTheme } from '../../../models/PersistenceModels';
import { createDefaultPreferences } from '../../../state/AppDefaults';
import { SETTINGS_SECTIONS } from '../../../mock/SupportingMockData';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { SettingRow } from './SettingRow';
import { MotionTokens } from '../../tokens/MotionTokens';

@Component
export struct SettingsPage {
  @State section: SettingsSection = 'General';
  @Prop preferences: AppPreferencesModel = createDefaultPreferences();
  @Prop phone: boolean = false;
  onChange: (preferences: AppPreferencesModel) => void = () => {};
  onExport: () => void = () => {};
  onExportSecrets: () => void = () => {};
  onReset: () => void = () => {};

  private emit(restoreWorkspace: boolean, language: 'en' | 'zh', followRedirects: boolean,
    sslVerification: boolean, defaultTimeoutMs: number, saveHistory: boolean,
    historyRetentionDays: number, maskSecrets: boolean): void {
    this.onChange({ restoreWorkspace, language, theme: this.preferences.theme,
      interfaceFont: this.preferences.interfaceFont,
      followRedirects, sslVerification, defaultTimeoutMs,
      saveHistory, historyRetentionDays, maskSecrets });
  }

  private themeLabel(): ResourceStr {
    if (this.preferences.theme === 'light') return $r('app.string.theme_light');
    if (this.preferences.theme === 'dark') return $r('app.string.theme_dark');
    return $r('app.string.theme_system');
  }

  private changeTheme(): void {
    const theme: NimboTheme = this.preferences.theme === 'system' ? 'light' :
      (this.preferences.theme === 'light' ? 'dark' : 'system');
    this.onChange({
      restoreWorkspace: this.preferences.restoreWorkspace,
      language: this.preferences.language,
      theme,
      interfaceFont: this.preferences.interfaceFont,
      followRedirects: this.preferences.followRedirects,
      sslVerification: this.preferences.sslVerification,
      defaultTimeoutMs: this.preferences.defaultTimeoutMs,
      saveHistory: this.preferences.saveHistory,
      historyRetentionDays: this.preferences.historyRetentionDays,
      maskSecrets: this.preferences.maskSecrets
    });
  }

  private fontLabel(): ResourceStr {
    if (this.preferences.interfaceFont === 'system') return $r('app.string.interface_font_system');
    if (this.preferences.interfaceFont === 'compact') return $r('app.string.interface_font_compact');
    return $r('app.string.interface_font_harmony');
  }

  private changeFont(): void {
    const interfaceFont: NimboFont = this.preferences.interfaceFont === 'harmony' ? 'system' :
      (this.preferences.interfaceFont === 'system' ? 'compact' : 'harmony');
    this.onChange({
      restoreWorkspace: this.preferences.restoreWorkspace,
      language: this.preferences.language,
      theme: this.preferences.theme,
      interfaceFont,
      followRedirects: this.preferences.followRedirects,
      sslVerification: this.preferences.sslVerification,
      defaultTimeoutMs: this.preferences.defaultTimeoutMs,
      saveHistory: this.preferences.saveHistory,
      historyRetentionDays: this.preferences.historyRetentionDays,
      maskSecrets: this.preferences.maskSecrets
    });
  }

  private timeoutLabel(): string {
    return this.preferences.language === 'zh' ? `${this.preferences.defaultTimeoutMs / 1000} 秒` :
      `${this.preferences.defaultTimeoutMs / 1000} seconds`;
  }

  private sectionLabel(section: SettingsSection): ResourceStr {
    if (section === 'General') return $r('app.string.settings_general');
    if (section === 'Appearance') return $r('app.string.settings_appearance');
    if (section === 'Network') return $r('app.string.settings_network');
    if (section === 'Data') return $r('app.string.settings_data');
    if (section === 'Privacy') return $r('app.string.settings_privacy');
    return $r('app.string.settings_about');
  }

  private nextTimeout(): number {
    if (this.preferences.defaultTimeoutMs === 15000) return 30000;
    if (this.preferences.defaultTimeoutMs === 30000) return 60000;
    if (this.preferences.defaultTimeoutMs === 60000) return 120000;
    return 15000;
  }

  private nextRetention(): number {
    if (this.preferences.historyRetentionDays === 7) return 30;
    if (this.preferences.historyRetentionDays === 30) return 90;
    return 7;
  }

  @Builder
  sectionContent() {
    if (this.section === 'General') {
      SettingRow({ title: $r('app.string.restore_workspace_title'),
        description: $r('app.string.restore_workspace_description'), toggle: true,
        checked: this.preferences.restoreWorkspace, onToggle: (value: boolean) => this.emit(value,
          this.preferences.language, this.preferences.followRedirects, this.preferences.sslVerification,
          this.preferences.defaultTimeoutMs, this.preferences.saveHistory,
          this.preferences.historyRetentionDays, this.preferences.maskSecrets) })
      SettingRow({ title: $r('app.string.language_title'), description: $r('app.string.language_description'),
        controlLabel: this.preferences.language === 'zh' ? $r('app.string.language_chinese') :
          $r('app.string.language_english'),
        onPress: () => this.emit(this.preferences.restoreWorkspace,
          this.preferences.language === 'en' ? 'zh' : 'en', this.preferences.followRedirects,
          this.preferences.sslVerification, this.preferences.defaultTimeoutMs,
          this.preferences.saveHistory, this.preferences.historyRetentionDays, this.preferences.maskSecrets) })
    } else if (this.section === 'Appearance') {
      SettingRow({ title: $r('app.string.theme_title'), description: $r('app.string.theme_description'),
        controlLabel: this.themeLabel(), onPress: () => this.changeTheme() })
      SettingRow({ title: $r('app.string.interface_font_title'),
        description: $r('app.string.interface_font_description'),
        controlLabel: this.fontLabel(), onPress: () => this.changeFont() })
    } else if (this.section === 'Network') {
      SettingRow({ title: $r('app.string.redirect_title'), description: $r('app.string.redirect_description'), toggle: true,
        checked: this.preferences.followRedirects, onToggle: (value: boolean) => this.emit(
          this.preferences.restoreWorkspace, this.preferences.language, value,
          this.preferences.sslVerification, this.preferences.defaultTimeoutMs,
          this.preferences.saveHistory, this.preferences.historyRetentionDays, this.preferences.maskSecrets) })
      SettingRow({ title: $r('app.string.ssl_title'), description: $r('app.string.ssl_description'), toggle: true,
        checked: this.preferences.sslVerification, onToggle: (value: boolean) => this.emit(
          this.preferences.restoreWorkspace, this.preferences.language, this.preferences.followRedirects,
          value, this.preferences.defaultTimeoutMs, this.preferences.saveHistory,
          this.preferences.historyRetentionDays, this.preferences.maskSecrets) })
      if (!this.preferences.sslVerification) {
        Text($r('app.string.ssl_warning'))
          .fontSize(12)
          .fontColor(ColorTokens.httpDelete)
          .width('100%')
          .padding(SpacingTokens.x3)
          .backgroundColor(ColorTokens.statusDangerBackground)
          .borderRadius(RadiusTokens.small)
      }
      SettingRow({ title: $r('app.string.timeout_title'), description: $r('app.string.timeout_description'),
        controlLabel: this.timeoutLabel(), onPress: () => this.emit(this.preferences.restoreWorkspace,
          this.preferences.language, this.preferences.followRedirects, this.preferences.sslVerification,
          this.nextTimeout(), this.preferences.saveHistory, this.preferences.historyRetentionDays,
          this.preferences.maskSecrets) })
    } else if (this.section === 'Data') {
      SettingRow({ title: $r('app.string.nimbo_export_title'),
        description: $r('app.string.nimbo_export_description'),
        controlLabel: $r('app.string.export_action'), onPress: this.onExport })
      SettingRow({ title: $r('app.string.save_history_title'), description: $r('app.string.save_history_description'), toggle: true,
        checked: this.preferences.saveHistory, onToggle: (value: boolean) => this.emit(
          this.preferences.restoreWorkspace, this.preferences.language, this.preferences.followRedirects,
          this.preferences.sslVerification, this.preferences.defaultTimeoutMs, value,
          this.preferences.historyRetentionDays, this.preferences.maskSecrets) })
      SettingRow({ title: $r('app.string.retention_title'), description: $r('app.string.retention_description'),
        controlLabel: this.preferences.language === 'zh' ? `${this.preferences.historyRetentionDays} 天` :
          `${this.preferences.historyRetentionDays} days`,
        onPress: () => this.emit(this.preferences.restoreWorkspace, this.preferences.language,
          this.preferences.followRedirects, this.preferences.sslVerification,
          this.preferences.defaultTimeoutMs, this.preferences.saveHistory, this.nextRetention(),
          this.preferences.maskSecrets) })
      SettingRow({ title: $r('app.string.reset_title'), description: $r('app.string.reset_description'),
        controlLabel: $r('app.string.reset_action'), dangerous: true, onPress: this.onReset })
    } else if (this.section === 'Privacy') {
      SettingRow({ title: $r('app.string.mask_secrets_title'), description: $r('app.string.mask_secrets_description'), toggle: true,
        checked: this.preferences.maskSecrets, onToggle: (value: boolean) => this.emit(
          this.preferences.restoreWorkspace, this.preferences.language, this.preferences.followRedirects,
          this.preferences.sslVerification, this.preferences.defaultTimeoutMs,
          this.preferences.saveHistory, this.preferences.historyRetentionDays, value) })
      SettingRow({ title: $r('app.string.export_secrets_title'), description: $r('app.string.export_secrets_description'),
        controlLabel: $r('app.string.export_action'), onPress: this.onExportSecrets })
    } else {
      SettingRow({ title: 'Nimbo', description: $r('app.string.about_description'), controlLabel: '0.1.0' })
      SettingRow({ title: $r('app.string.application_identity'),
        description: 'Bundle com.nimbo.app · App ID 6917615930484878194', controlLabel: $r('app.string.local_build') })
    }
  }

  build() {
    if (this.phone) {
      Column() {
        Scroll() {
          Row({ space: SpacingTokens.x2 }) {
            ForEach(SETTINGS_SECTIONS, (item: SettingsSectionModel) => {
              Row({ space: SpacingTokens.x2 }) {
                Text(item.icon).fontSize(14)
                  .fontColor(item.id === this.section ? ColorTokens.brand500 : ColorTokens.textTertiary)
                Text(this.sectionLabel(item.id)).fontSize(12)
                  .fontColor(item.id === this.section ? ColorTokens.brand600 : ColorTokens.textSecondary)
              }
              .height(40)
              .padding({ left: SpacingTokens.x3, right: SpacingTokens.x3 })
              .backgroundColor(item.id === this.section ? ColorTokens.bgSurfaceActive : ColorTokens.bgSurface)
              .borderRadius(RadiusTokens.medium)
              .animation({ duration: MotionTokens.fast, curve: MotionTokens.standardCurve })
              .onClick(() => {
                this.getUIContext().animateTo({ duration: MotionTokens.normal,
                  curve: MotionTokens.standardCurve }, () => { this.section = item.id; });
              })
            }, (item: SettingsSectionModel) => item.id)
          }
          .padding({ left: SpacingTokens.x3, right: SpacingTokens.x3 })
        }
        .width('100%')
        .height(56)
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .backgroundColor(ColorTokens.bgSidebar)

        Scroll() {
          Column() {
            Text(this.sectionLabel(this.section)).fontSize(20).fontWeight(FontWeight.Medium)
              .fontColor(ColorTokens.textPrimary).width('100%')
            Text($r('app.string.settings_description')).fontSize(12).fontColor(ColorTokens.textTertiary)
              .width('100%').margin({ top: SpacingTokens.x1, bottom: SpacingTokens.x4 })
            this.sectionContent()
          }
          .width('100%')
          .padding({ left: SpacingTokens.x4, right: SpacingTokens.x4, top: SpacingTokens.x4, bottom: 40 })
        }
        .layoutWeight(1)
        .width('100%')
        .align(Alignment.TopStart)
      }
      .width('100%').height('100%').backgroundColor(ColorTokens.bgWorkspace)
    } else {
      Row() {
        Column() {
          Text($r('app.string.settings_title')).fontSize(15).fontWeight(FontWeight.Medium)
            .fontColor(ColorTokens.textPrimary).width('100%').height(48).padding({ left: SpacingTokens.x3 })
          ForEach(SETTINGS_SECTIONS, (item: SettingsSectionModel) => {
            Row({ space: SpacingTokens.x3 }) {
              Text(item.icon).width(20).fontSize(15).textAlign(TextAlign.Center)
                .fontColor(item.id === this.section ? ColorTokens.brand500 : ColorTokens.textTertiary)
              Text(this.sectionLabel(item.id)).fontSize(13)
                .fontColor(item.id === this.section ? ColorTokens.brand600 : ColorTokens.textSecondary)
            }
            .width('100%').height(40).padding({ left: SpacingTokens.x3 })
            .backgroundColor(item.id === this.section ? ColorTokens.bgSurfaceActive : ColorTokens.bgSidebar)
            .borderRadius(RadiusTokens.medium)
            .animation({ duration: MotionTokens.fast, curve: MotionTokens.standardCurve })
            .onClick(() => {
              this.getUIContext().animateTo({ duration: MotionTokens.normal,
                curve: MotionTokens.standardCurve }, () => { this.section = item.id; });
            })
          }, (item: SettingsSectionModel) => item.id)
          Blank()
        }
        .width(220).height('100%').padding(SpacingTokens.x2).backgroundColor(ColorTokens.bgSidebar)
        .border({ width: { right: 1 }, color: ColorTokens.borderSubtle })

        Scroll() {
          Column() {
            Text(this.sectionLabel(this.section)).fontSize(22).fontWeight(FontWeight.Medium)
              .fontColor(ColorTokens.textPrimary).width('100%')
            Text($r('app.string.settings_description')).fontSize(12).fontColor(ColorTokens.textTertiary)
              .width('100%').margin({ top: SpacingTokens.x1, bottom: SpacingTokens.x5 })
            this.sectionContent()
          }
          .width('100%').padding({ left: 40, right: 40, top: 30, bottom: 40 })
        }
        .layoutWeight(1).height('100%').align(Alignment.TopStart)
        .backgroundColor(ColorTokens.bgWorkspace)
      }
      .width('100%').height('100%')
    }
  }
}
