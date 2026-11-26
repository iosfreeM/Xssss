import SwiftUI
import UIKit

// MARK: - Настройки (правь здесь)

let contentURLString = "https://raw.githubusercontent.com/iosfreeM/MtechApp/main/content.json"
let aboutName = "Mtech"
let aboutText = "Разработчик. Делаю приложения, твики и туторы для iOS."
let links: [(title: String, icon: String, url: String)] = [
    ("GitHub", "chevron.left.forwardslash.chevron.right", "https://github.com/iosfreeM"),
    ("TikTok", "play.rectangle", "https://www.tiktok.com/"),   // вставь свою ссылку
    ("Telegram-канал", "paperplane", "https://t.me/")           // вставь свою ссылку
]

// MARK: - Темы

struct AppTheme: Identifiable {
    let id: String
    let name: String
    let accent: Color
    let bgTop: Color
}

let themes: [AppTheme] = [
    AppTheme(id: "mint", name: "Мята", accent: .green, bgTop: Color(red: 0.00, green: 0.20, blue: 0.12)),
    AppTheme(id: "ocean", name: "Океан", accent: .blue, bgTop: Color(red: 0.00, green: 0.12, blue: 0.28)),
    AppTheme(id: "violet", name: "Фиалка", accent: .purple, bgTop: Color(red: 0.18, green: 0.06, blue: 0.30)),
    AppTheme(id: "sunset", name: "Закат", accent: .orange, bgTop: Color(red: 0.30, green: 0.12, blue: 0.02)),
    AppTheme(id: "rose", name: "Роза", accent: .pink, bgTop: Color(red: 0.30, green: 0.04, blue: 0.14)),
    AppTheme(id: "graphite", name: "Графит", accent: .gray, bgTop: Color(red: 0.16, green: 0.16, blue: 0.18))
]

func theme(for id: String) -> AppTheme {
    themes.first { $0.id == id } ?? themes[0]
}

enum Appearance: String {
    case system, dark, light

    var scheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .dark: return .dark
        case .light: return .light
        }
    }
}

struct ThemeBackground: View {
    @AppStorage("themeID") private var themeID = "mint"
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = theme(for: themeID)
        LinearGradient(
            colors: scheme == .dark
                ? [t.bgTop, Color.black]
                : [t.accent.opacity(0.28), Color(.systemBackground)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// MARK: - Liquid Glass
// На iOS 26+ и сборке Xcode 26 используется настоящий Liquid Glass.
// На старых системах или старом Xcode — стеклянный блюр (Material).

struct GlassCard: ViewModifier {
    @AppStorage("glassOn") private var glassOn = true
    var radius: CGFloat = 18

    @ViewBuilder
    func body(content: Self.Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        if !glassOn {
            content.background(Color(.secondarySystemBackground), in: shape)
        } else {
            #if compiler(>=6.2)
            if #available(iOS 26.0, *) {
                content.glassEffect(.regular, in: shape)
            } else {
                content
                    .background(.ultraThinMaterial, in: shape)
                    .overlay(shape.stroke(Color.white.opacity(0.12), lineWidth: 0.5))
            }
            #else
            content
                .background(.ultraThinMaterial, in: shape)
                .overlay(shape.stroke(Color.white.opacity(0.12), lineWidth: 0.5))
            #endif
        }
    }
}

extension View {
    func glassCard(radius: CGFloat = 18) -> some View {
        modifier(GlassCard(radius: radius))
    }
}

// MARK: - Модели

struct AppItem: Identifiable, Codable {
    var id: String { name + version }
    let name: String
    let version: String
    let category: String
    let description: String
    let url: String
}

struct Tutorial: Identifiable, Codable {
    var id: String { title }
    let title: String
    let category: String
    let icon: String
    let steps: [String]
}

struct Latest: Codable {
    let title: String
    let text: String
}

struct RemoteContent: Codable {
    var apps: [AppItem]
    var tutorials: [Tutorial]
    var latest: Latest?

    enum CodingKeys: String, CodingKey { case apps, tutorials, latest }

    init(apps: [AppItem], tutorials: [Tutorial], latest: Latest?) {
        self.apps = apps
        self.tutorials = tutorials
        self.latest = latest
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        apps = try c.decodeIfPresent([AppItem].self, forKey: .apps) ?? []
        tutorials = try c.decodeIfPresent([Tutorial].self, forKey: .tutorials) ?? []
        latest = try c.decodeIfPresent(Latest.self, forKey: .latest)
    }

    static let fallback = RemoteContent(
        apps: [
            AppItem(name: "MtechApp", version: "1.0", category: "Мои приложения",
                    description: "Каталог, туторы и утилиты в одном приложении.",
                    url: "https://github.com/iosfreeM")
        ],
        tutorials: [
            Tutorial(title: "Установка IPA через Sideloadly", category: "Установка", icon: "square.and.arrow.down",
                     steps: ["Установи Sideloadly на ПК или Mac.",
                             "Подключи iPhone кабелем и доверься компьютеру.",
                             "Перетащи IPA в окно и введи Apple ID.",
                             "Нажми Start и дождись установки.",
                             "Настройки → Основные → VPN и управление устройством → доверься профилю."]),
            Tutorial(title: "Подпись IPA сертификатом", category: "Сертификаты", icon: "checkmark.seal",
                     steps: ["Подготовь .p12, .mobileprovision и пароль.",
                             "Импортируй сертификат в подписчик (например ESign).",
                             "Выбери IPA и нажми «Подписать».",
                             "Установи приложение и доверься профилю."]),
            Tutorial(title: "Сертификат отозван: что делать", category: "Сертификаты", icon: "exclamationmark.triangle",
                     steps: ["Проверь статус сертификата в подписчике.",
                             "Удали приложение и профиль в Настройках.",
                             "Установи новый сертификат и подпиши IPA заново."])
        ],
        latest: Latest(title: "Mtech", text: "Добро пожаловать!")
    )
}

// MARK: - Хранилище контента (JSON с GitHub + кэш)

final class Store: ObservableObject {
    @Published var content: RemoteContent
    @Published var loading = false
    @Published var error: String?

    init() {
        if let data = UserDefaults.standard.data(forKey: "cachedContent"),
           let cached = try? JSONDecoder().decode(RemoteContent.self, from: data) {
            content = cached
        } else {
            content = RemoteContent.fallback
        }
    }

    func refresh() async {
        guard let url = URL(string: contentURLString) else { return }
        await MainActor.run { self.loading = true }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            var decoded = try JSONDecoder().decode(RemoteContent.self, from: data)
            if decoded.tutorials.isEmpty { decoded.tutorials = RemoteContent.fallback.tutorials }
            let result = decoded
            UserDefaults.standard.set(data, forKey: "cachedContent")
            await MainActor.run {
                self.content = result
                self.error = nil
                self.loading = false
            }
        } catch {
            await MainActor.run {
                self.error = "Нет обновления, показаны сохранённые данные"
                self.loading = false
            }
        }
    }
}

// MARK: - App

@main
struct MtechApp: App {
    @StateObject private var store = Store()

    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(store)
        }
    }
}

struct RootView: View {
    @AppStorage("themeID") private var themeID = "mint"
    @AppStorage("appearance") private var appearance = "dark"

    var body: some View {
        TabView {
            CatalogView()
                .tabItem { Label("Каталог", systemImage: "square.grid.2x2") }
            CompatibilityView()
                .tabItem { Label("Совместимость", systemImage: "checkmark.shield") }
            DeviceView()
                .tabItem { Label("Устройство", systemImage: "iphone") }
            MoreView()
                .tabItem { Label("Ещё", systemImage: "ellipsis.circle") }
        }
        .tint(theme(for: themeID).accent)
        .preferredColorScheme(Appearance(rawValue: appearance)?.scheme)
    }
}

// MARK: - Каталог IPA

struct CatalogView: View {
    @EnvironmentObject var store: Store
    @State private var query = ""

    private var items: [AppItem] {
        query.isEmpty
            ? store.content.apps
            : store.content.apps.filter {
                $0.name.localizedCaseInsensitiveContains(query)
                || $0.category.localizedCaseInsensitiveContains(query)
            }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(items) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(item.name).font(.headline)
                                Spacer()
                                Text("v\(item.version)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(item.category)
                                .font(.caption)
                                .foregroundColor(.accentColor)
                            Text(item.description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            if let url = URL(string: item.url) {
                                Button {
                                    UIApplication.shared.open(url)
                                } label: {
                                    Label("Скачать", systemImage: "arrow.down.circle.fill")
                                }
                                .buttonStyle(.borderless)
                                .padding(.top, 4)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .glassCard()
                    }
                    if items.isEmpty {
                        Text("Ничего не найдено")
                            .foregroundStyle(.secondary)
                            .padding()
                    }
                    if let error = store.error {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .background(ThemeBackground())
            .searchable(text: $query, prompt: "Поиск по каталогу")
            .refreshable { await store.refresh() }
            .navigationTitle("Каталог")
        }
        .task { await store.refresh() }
    }
}

// MARK: - Проверка совместимости

struct Method: Identifiable {
    let id = UUID()
    let name: String
    let ranges: [(String, String)]
    let note: String
}

// Стартовая таблица: проверяй актуальность на страницах проектов и правь под себя.
let methods: [Method] = [
    Method(name: "Подпись сертификатом (ESign, Sideloadly, AltStore)",
           ranges: [("12.0", "99.0")],
           note: "Работает на любой iOS, которую поддерживает сам IPA. Нужен действующий сертификат или Apple ID."),
    Method(name: "TrollStore",
           ranges: [("14.0", "16.6.1"), ("17.0", "17.0")],
           note: "Постоянная установка без отзыва. Также подходит iOS 16.7 RC (20H18), проверь свою сборку."),
    Method(name: "Dopamine (rootless-джейлбрейк)",
           ranges: [("15.0", "15.8.3"), ("16.0", "16.5.1")],
           note: "Нужен чип A12 и новее. Сверься со страницей проекта перед установкой.")
]

func parseVersion(_ s: String) -> [Int] {
    s.split(separator: ".").map { Int($0) ?? 0 }
}

func compareVersions(_ a: [Int], _ b: [Int]) -> Int {
    for i in 0..<max(a.count, b.count) {
        let x = i < a.count ? a[i] : 0
        let y = i < b.count ? b[i] : 0
        if x != y { return x < y ? -1 : 1 }
    }
    return 0
}

func supports(_ method: Method, version: String) -> Bool {
    let v = parseVersion(version)
    return method.ranges.contains {
        compareVersions(v, parseVersion($0.0)) >= 0 && compareVersions(v, parseVersion($0.1)) <= 0
    }
}

func machineIdentifier() -> String {
    var sys = utsname()
    uname(&sys)
    return withUnsafePointer(to: &sys.machine) {
        $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }
    }
}

struct CompatibilityView: View {
    @State private var version = UIDevice.current.systemVersion

    private var okMethods: [Method] { methods.filter { supports($0, version: version) } }
    private var noMethods: [Method] { methods.filter { !supports($0, version: version) } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Модель")
                            Spacer()
                            Text(machineIdentifier()).foregroundStyle(.secondary)
                        }
                        Divider()
                        HStack {
                            Text("Версия iOS")
                            Spacer()
                            TextField("16.5", text: $version)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 120)
                        }
                    }
                    .padding()
                    .glassCard()

                    ForEach(okMethods) { row($0, ok: true) }
                    ForEach(noMethods) { row($0, ok: false) }

                    Text("Таблица стартовая. Версии могут меняться, проверяй страницу каждого проекта.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .background(ThemeBackground())
            .navigationTitle("Совместимость")
        }
    }

    private func row(_ m: Method, ok: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(ok ? .green : .red)
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text(m.name).font(.headline)
                Text(ok ? "Подходит для iOS \(version)" : "Не подходит для iOS \(version)")
                    .font(.caption)
                    .foregroundColor(ok ? .green : .secondary)
                Text(m.note)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding()
        .glassCard()
    }
}

// MARK: - Инфо об устройстве

enum DeviceInfo {
    static func rows() -> [(String, String)] {
        let d = UIDevice.current
        d.isBatteryMonitoringEnabled = true
        let p = ProcessInfo.processInfo
        var rows: [(String, String)] = []

        rows.append(("Устройство", d.model))
        rows.append(("Идентификатор", machineIdentifier()))
        rows.append(("iOS", d.systemVersion))
        rows.append(("ОЗУ", String(format: "%.1f ГБ", Double(p.physicalMemory) / 1_073_741_824)))
        rows.append(("Ядра CPU", "\(p.processorCount)"))

        let level = d.batteryLevel
        rows.append(("Батарея", level < 0 ? "—" : "\(Int(level * 100))%"))
        let state: String
        switch d.batteryState {
        case .charging: state = "Заряжается"
        case .full: state = "Заряжено"
        case .unplugged: state = "От батареи"
        default: state = "—"
        }
        rows.append(("Питание", state))
        rows.append(("Экономия энергии", p.isLowPowerModeEnabled ? "Включена" : "Выключена"))

        let thermal: String
        switch p.thermalState {
        case .nominal: thermal = "Норма"
        case .fair: thermal = "Тепло"
        case .serious: thermal = "Горячо"
        case .critical: thermal = "Критично"
        @unknown default: thermal = "—"
        }
        rows.append(("Температура", thermal))

        if let values = try? URL(fileURLWithPath: NSHomeDirectory())
            .resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey]),
           let total = values.volumeTotalCapacity,
           let free = values.volumeAvailableCapacityForImportantUsage {
            let fmt = { (bytes: Int64) in ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file) }
            rows.append(("Память всего", fmt(Int64(total))))
            rows.append(("Свободно", fmt(free)))
        }
        return rows
    }
}

struct DeviceView: View {
    @State private var rows: [(String, String)] = DeviceInfo.rows()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(rows, id: \.0) { row in
                        VStack(spacing: 0) {
                            HStack {
                                Text(row.0)
                                Spacer()
                                Text(row.1)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.trailing)
                            }
                            .padding(.vertical, 12)
                            if row.0 != rows.last?.0 { Divider() }
                        }
                    }
                }
                .padding(.horizontal)
                .glassCard()
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .background(ThemeBackground())
            .refreshable { rows = DeviceInfo.rows() }
            .navigationTitle("Устройство")
        }
        .onAppear { rows = DeviceInfo.rows() }
    }
}

// MARK: - Ещё: туторы, «Обо мне», оформление

struct MoreRow: View {
    let title: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 28)
                .foregroundColor(.accentColor)
            Text(title).foregroundStyle(.primary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .glassCard()
    }
}

struct MoreView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    NavigationLink { TutorialsList() } label: {
                        MoreRow(title: "Туторы", icon: "book")
                    }
                    NavigationLink { AppearanceView() } label: {
                        MoreRow(title: "Оформление", icon: "paintpalette")
                    }
                    NavigationLink { AboutContent() } label: {
                        MoreRow(title: "Обо мне", icon: "person.crop.circle")
                    }
                    Text("Виджет: удерживай пустое место на рабочем столе → «+» → Mtech.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .background(ThemeBackground())
            .navigationTitle("Ещё")
        }
    }
}

struct AppearanceView: View {
    @AppStorage("themeID") private var themeID = "mint"
    @AppStorage("appearance") private var appearance = "dark"
    @AppStorage("glassOn") private var glassOn = true

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Тема").font(.headline)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 12)], spacing: 14) {
                        ForEach(themes) { t in
                            Button {
                                themeID = t.id
                            } label: {
                                VStack(spacing: 6) {
                                    ZStack {
                                        Circle()
                                            .fill(LinearGradient(colors: [t.accent, t.bgTop],
                                                                 startPoint: .topLeading,
                                                                 endPoint: .bottomTrailing))
                                            .frame(width: 52, height: 52)
                                        if themeID == t.id {
                                            Image(systemName: "checkmark")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                        }
                                    }
                                    Text(t.name)
                                        .font(.caption)
                                        .foregroundStyle(.primary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Оформление").font(.headline)
                    Picker("", selection: $appearance) {
                        Text("Системное").tag("system")
                        Text("Тёмное").tag("dark")
                        Text("Светлое").tag("light")
                    }
                    .pickerStyle(.segmented)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .glassCard()

                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Эффект стекла", isOn: $glassOn)
                    Text("На iOS 26 и новее это настоящий Liquid Glass, на старых версиях стеклянный блюр.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .glassCard()
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .background(ThemeBackground())
        .navigationTitle("Оформление")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TutorialsList: View {
    @EnvironmentObject var store: Store
    @State private var query = ""

    private var filtered: [Tutorial] {
        query.isEmpty
            ? store.content.tutorials
            : store.content.tutorials.filter {
                $0.title.localizedCaseInsensitiveContains(query)
                || $0.category.localizedCaseInsensitiveContains(query)
            }
    }

    private var categories: [String] {
        Array(Set(filtered.map { $0.category })).sorted()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(categories, id: \.self) { category in
                    Text(category)
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                    ForEach(filtered.filter { $0.category == category }) { tutorial in
                        NavigationLink {
                            TutorialDetail(tutorial: tutorial)
                        } label: {
                            MoreRow(title: tutorial.title, icon: tutorial.icon)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 4)
        }
        .background(ThemeBackground())
        .searchable(text: $query, prompt: "Поиск по туторам")
        .navigationTitle("Туторы")
    }
}

struct TutorialDetail: View {
    let tutorial: Tutorial

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(Array(tutorial.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.accentColor)
                            .clipShape(Circle())
                        Text(step)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .padding()
                    .glassCard()
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .background(ThemeBackground())
        .navigationTitle(tutorial.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutContent: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ZStack {
                    Circle().fill(Color.accentColor.opacity(0.25))
                    Text("M")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.accentColor)
                }
                .frame(width: 110, height: 110)
                .padding(.top, 24)

                Text(aboutName).font(.largeTitle.bold())
                Text(aboutText)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                VStack(spacing: 10) {
                    ForEach(links, id: \.title) { item in
                        if let url = URL(string: item.url) {
                            Link(destination: url) {
                                HStack {
                                    Image(systemName: item.icon).frame(width: 28)
                                    Text(item.title)
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                                .glassCard(radius: 14)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
        .background(ThemeBackground())
        .navigationTitle("Обо мне")
        .navigationBarTitleDisplayMode(.inline)
    }
}
