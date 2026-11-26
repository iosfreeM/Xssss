import SwiftUI
import UIKit
import UniformTypeIdentifiers

// MARK: - Настройки (правь здесь)

let contentURLString = "https://raw.githubusercontent.com/iosfreeM/MtechApp/main/content.json"
let aboutName = "Mtech"
let aboutText = "Разработчик. Делаю приложения, твики и туторы для iOS."
let links: [(title: String, icon: String, url: String)] = [
    ("GitHub", "chevron.left.forwardslash.chevron.right", "https://github.com/iosfreeM"),
    ("TikTok", "play.rectangle", "https://www.tiktok.com/"),   // вставь свою ссылку
    ("Telegram-канал", "paperplane", "https://t.me/")           // вставь свою ссылку
]

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

struct Content: Codable {
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

    static let fallback = Content(
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
    @Published var content: Content
    @Published var loading = false
    @Published var error: String?

    init() {
        if let data = UserDefaults.standard.data(forKey: "cachedContent"),
           let cached = try? JSONDecoder().decode(Content.self, from: data) {
            content = cached
        } else {
            content = Content.fallback
        }
    }

    func refresh() async {
        guard let url = URL(string: contentURLString) else { return }
        await MainActor.run { self.loading = true }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            var decoded = try JSONDecoder().decode(Content.self, from: data)
            if decoded.tutorials.isEmpty { decoded.tutorials = Content.fallback.tutorials }
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
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .tint(.green)
        }
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            CatalogView()
                .tabItem { Label("Каталог", systemImage: "square.grid.2x2") }
            CompatibilityView()
                .tabItem { Label("Совместимость", systemImage: "checkmark.shield") }
            DeviceView()
                .tabItem { Label("Устройство", systemImage: "iphone") }
            StorageView()
                .tabItem { Label("Хранилище", systemImage: "folder") }
            MoreView()
                .tabItem { Label("Ещё", systemImage: "ellipsis.circle") }
        }
    }
}

// MARK: - 1. Каталог IPA

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
            List(items) { item in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(item.name).font(.headline)
                        Spacer()
                        Text("v\(item.version)").font(.caption).foregroundColor(.secondary)
                    }
                    Text(item.category).font(.caption).foregroundColor(.green)
                    Text(item.description).font(.subheadline).foregroundColor(.secondary)
                    if let url = URL(string: item.url) {
                        Button {
                            UIApplication.shared.open(url)
                        } label: {
                            Label("Скачать", systemImage: "arrow.down.circle.fill")
                        }
                        .buttonStyle(.borderless)
                        .padding(.top, 2)
                    }
                }
                .padding(.vertical, 4)
            }
            .searchable(text: $query, prompt: "Поиск по каталогу")
            .refreshable { await store.refresh() }
            .navigationTitle("Каталог")
            .safeAreaInset(edge: .bottom) {
                if let error = store.error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(6)
                }
            }
        }
        .task { await store.refresh() }
    }
}

// MARK: - 2. Проверка совместимости

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

    var body: some View {
        NavigationStack {
            List {
                Section("Твоё устройство") {
                    HStack {
                        Text("Модель")
                        Spacer()
                        Text(machineIdentifier()).foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Версия iOS")
                        Spacer()
                        TextField("16.5", text: $version)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 120)
                    }
                }
                Section("Что подходит") {
                    let ok = methods.filter { supports($0, version: version) }
                    let no = methods.filter { !supports($0, version: version) }
                    ForEach(ok) { row($0, ok: true) }
                    ForEach(no) { row($0, ok: false) }
                }
                Section {
                    Text("Таблица стартовая. Версии могут меняться, проверяй страницу каждого проекта.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
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
                Text(m.note).font(.footnote).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - 4. Инфо об устройстве

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
            List {
                ForEach(rows, id: \.0) { row in
                    HStack {
                        Text(row.0)
                        Spacer()
                        Text(row.1)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .refreshable { rows = DeviceInfo.rows() }
            .navigationTitle("Устройство")
        }
        .onAppear { rows = DeviceInfo.rows() }
    }
}

// MARK: - 5. Хранилище: ссылки и файлы

struct Bookmark: Identifiable, Codable {
    var id = UUID()
    var title: String
    var url: String
    var note: String
}

final class BookmarkStore: ObservableObject {
    @Published var items: [Bookmark] {
        didSet { save() }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: "bookmarks"),
           let saved = try? JSONDecoder().decode([Bookmark].self, from: data) {
            items = saved
        } else {
            items = []
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: "bookmarks")
        }
    }
}

struct StorageView: View {
    enum Mode: String, CaseIterable {
        case links = "Ссылки"
        case files = "Файлы"
    }
    @State private var mode: Mode = .links

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $mode) {
                    ForEach(Mode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding()

                switch mode {
                case .links: LinksView()
                case .files: FilesView()
                }
            }
            .navigationTitle("Хранилище")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct LinksView: View {
    @StateObject private var store = BookmarkStore()
    @State private var adding = false

    var body: some View {
        List {
            ForEach(store.items) { item in
                Button {
                    if let url = URL(string: item.url) { UIApplication.shared.open(url) }
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.title.isEmpty ? item.url : item.title).font(.headline)
                        Text(item.url).font(.caption).foregroundColor(.green).lineLimit(1)
                        if !item.note.isEmpty {
                            Text(item.note).font(.footnote).foregroundColor(.secondary)
                        }
                    }
                }
            }
            .onDelete { store.items.remove(atOffsets: $0) }
        }
        .overlay {
            if store.items.isEmpty {
                Text("Пока пусто. Нажми «+», чтобы добавить ссылку.")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { adding = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $adding) {
            AddBookmarkSheet { store.items.append($0) }
        }
    }
}

struct AddBookmarkSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var url = ""
    @State private var note = ""
    let onSave: (Bookmark) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Название", text: $title)
                TextField("Ссылка", text: $url)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("Заметка", text: $note)
            }
            .navigationTitle("Новая ссылка")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        var link = url.trimmingCharacters(in: .whitespaces)
                        if !link.lowercased().hasPrefix("http") { link = "https://" + link }
                        onSave(Bookmark(title: title, url: link, note: note))
                        dismiss()
                    }
                    .disabled(url.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

struct SavedFile: Identifiable {
    let url: URL
    let size: Int64
    var id: String { url.lastPathComponent }
}

struct FilesView: View {
    @State private var files: [SavedFile] = []
    @State private var importing = false

    private var docs: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    var body: some View {
        List {
            ForEach(files) { file in
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(file.url.lastPathComponent).font(.headline).lineLimit(1)
                        Text(ByteCountFormatter.string(fromByteCount: file.size, countStyle: .file))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    ShareLink(item: file.url) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .buttonStyle(.borderless)
                }
            }
            .onDelete { offsets in
                for i in offsets { try? FileManager.default.removeItem(at: files[i].url) }
                reload()
            }
        }
        .overlay {
            if files.isEmpty {
                Text("Файлов нет. Нажми «+», чтобы добавить IPA, сертификат или любой файл.")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { importing = true } label: { Image(systemName: "plus") }
            }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.item], allowsMultipleSelection: true) { result in
            if case .success(let urls) = result {
                for u in urls {
                    let access = u.startAccessingSecurityScopedResource()
                    let dest = docs.appendingPathComponent(u.lastPathComponent)
                    try? FileManager.default.removeItem(at: dest)
                    try? FileManager.default.copyItem(at: u, to: dest)
                    if access { u.stopAccessingSecurityScopedResource() }
                }
                reload()
            }
        }
        .onAppear { reload() }
    }

    private func reload() {
        let urls = (try? FileManager.default.contentsOfDirectory(
            at: docs,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles])) ?? []
        files = urls.map { url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return SavedFile(url: url, size: Int64(size))
        }
        .sorted { $0.id < $1.id }
    }
}

// MARK: - Ещё: туторы и «Обо мне»

struct MoreView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink { TutorialsList() } label: {
                    Label("Туторы", systemImage: "book")
                }
                NavigationLink { AboutContent() } label: {
                    Label("Обо мне", systemImage: "person.crop.circle")
                }
                Section("Виджет") {
                    Text("Удерживай пустое место на рабочем столе → «+» → Mtech.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Ещё")
        }
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
        List {
            ForEach(categories, id: \.self) { category in
                Section(category) {
                    ForEach(filtered.filter { $0.category == category }) { tutorial in
                        NavigationLink {
                            TutorialDetail(tutorial: tutorial)
                        } label: {
                            Label(tutorial.title, systemImage: tutorial.icon)
                        }
                    }
                }
            }
        }
        .searchable(text: $query, prompt: "Поиск по туторам")
        .navigationTitle("Туторы")
    }
}

struct TutorialDetail: View {
    let tutorial: Tutorial

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(tutorial.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(width: 28, height: 28)
                            .background(Color.green)
                            .clipShape(Circle())
                        Text(step)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(tutorial.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutContent: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ZStack {
                    Circle().fill(Color.green.opacity(0.2))
                    Text("M")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                }
                .frame(width: 110, height: 110)
                .padding(.top, 24)

                Text(aboutName).font(.largeTitle.bold())
                Text(aboutText)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
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
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
        .navigationTitle("Обо мне")
        .navigationBarTitleDisplayMode(.inline)
    }
}
