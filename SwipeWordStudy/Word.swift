import Foundation

enum StudyState: String, Codable {
    case new = "새 단어"
    case memorized = "외움"
    case review = "다시 보기"
}

struct Word: Equatable, Codable {
    let term: String
    let meaning: String
    let reading: String
    let example: String
    let exampleMeaning: String
    var state: StudyState

    init(
        term: String,
        meaning: String,
        reading: String,
        example: String,
        exampleMeaning: String = "",
        state: StudyState
    ) {
        self.term = term
        self.meaning = meaning
        self.reading = reading
        self.example = example
        self.exampleMeaning = exampleMeaning
        self.state = state
    }

    private enum CodingKeys: String, CodingKey {
        case term
        case meaning
        case reading
        case example
        case exampleMeaning
        case state
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        term = try container.decode(String.self, forKey: .term)
        meaning = try container.decode(String.self, forKey: .meaning)
        reading = try container.decode(String.self, forKey: .reading)
        example = try container.decode(String.self, forKey: .example)
        exampleMeaning = try container.decodeIfPresent(String.self, forKey: .exampleMeaning) ?? ""
        state = try container.decode(StudyState.self, forKey: .state)
    }
}

struct WordBook: Equatable, Codable {
    let id: String
    var name: String
    var words: [Word]
}

final class WordStore {
    static let shared = WordStore()

    private static let storageKey = "savedWords"
    private static let customBooksKey = "customWordBooks"
    private static let sessionWordCountKey = "sessionWordCount"
    private static let completedSessionsKey = "completedStudySessions"
    private static let quickStudyBookIDKey = "quickStudyBookID"
    private static let targetDateKey = "targetDate"
    private static let targetNameKey = "targetName"
    private static let dDayEnabledKey = "dDayEnabled"
    private static let studyDaysKey = "studyDays"
    private(set) var customBooks: [WordBook]

    private init() {
        customBooks = WordStore.loadCustomBooks()
    }

    var books: [WordBook] {
        [WordBook(id: "default", name: "기본 단어장", words: WordStore.loadSavedWords())] + customBooks
    }

    var words: [Word] {
        books.flatMap { $0.words }
    }

    var quickStudyBook: WordBook {
        if
            let savedID = UserDefaults.standard.string(forKey: WordStore.quickStudyBookIDKey),
            let book = wordBook(id: savedID)
        {
            return book
        }

        let defaultBook = books.first { $0.id == "default" } ?? books[0]
        UserDefaults.standard.set(defaultBook.id, forKey: WordStore.quickStudyBookIDKey)
        return defaultBook
    }

    var sessionWordCount: Int {
        get {
            let savedCount = UserDefaults.standard.integer(forKey: WordStore.sessionWordCountKey)
            return savedCount > 0 ? savedCount : 10
        }
        set {
            let limitedCount = max(5, min(newValue, max(words.count, 5)))
            let oldCount = sessionWordCount
            UserDefaults.standard.set(limitedCount, forKey: WordStore.sessionWordCountKey)
            if oldCount != limitedCount {
                resetSessionHistory()
            }
        }
    }

    var targetDate: Date? {
        get {
            guard let savedDate = UserDefaults.standard.object(forKey: WordStore.targetDateKey) as? Date else {
                return nil
            }
            return Calendar.current.startOfDay(for: savedDate)
        }
        set {
            if let newValue = newValue {
                UserDefaults.standard.set(Calendar.current.startOfDay(for: newValue), forKey: WordStore.targetDateKey)
            } else {
                UserDefaults.standard.removeObject(forKey: WordStore.targetDateKey)
            }
        }
    }

    var targetName: String {
        get {
            let savedName = UserDefaults.standard.string(forKey: WordStore.targetNameKey)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return savedName
        }
        set {
            let trimmedName = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedName.isEmpty {
                UserDefaults.standard.removeObject(forKey: WordStore.targetNameKey)
            } else {
                UserDefaults.standard.set(trimmedName, forKey: WordStore.targetNameKey)
            }
        }
    }

    var targetNameDescription: String {
        return targetName.isEmpty ? "D-day 이름을 설정해 주세요" : targetName
    }

    var isDdayEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: WordStore.dDayEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: WordStore.dDayEnabledKey)
        }
    }

    var shouldShowDday: Bool {
        isDdayEnabled && targetDate != nil
    }

    var dDayText: String {
        guard let targetDate = targetDate else { return "D-day 설정" }
        let today = Calendar.current.startOfDay(for: Date())
        let days = Calendar.current.dateComponents([.day], from: today, to: targetDate).day ?? 0
        if days > 0 { return "D-\(days)" }
        if days == 0 { return "D-day" }
        return "D+\(abs(days))"
    }

    var targetDateDescription: String {
        guard let targetDate = targetDate else { return "시험 날짜를 설정해 주세요" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일"
        return formatter.string(from: targetDate)
    }

    var streakCount: Int {
        let days = Set(UserDefaults.standard.stringArray(forKey: WordStore.studyDaysKey) ?? [])
        guard !days.isEmpty else { return 0 }

        var count = 0
        var date = Calendar.current.startOfDay(for: Date())
        while days.contains(WordStore.dayKey(for: date)) {
            count += 1
            guard let previousDate = Calendar.current.date(byAdding: .day, value: -1, to: date) else { break }
            date = previousDate
        }
        return count
    }

    func setQuickStudyBook(id: String) {
        guard wordBook(id: id) != nil else { return }
        UserDefaults.standard.set(id, forKey: WordStore.quickStudyBookIDKey)
    }

    func nextQuickStudySession() -> (book: WordBook, index: Int, words: [Word]) {
        let book = quickStudyBook
        let sessionIndex = nextIncompleteSessionIndex(for: book)
        return (book, sessionIndex, wordsForSession(book: book, index: sessionIndex))
    }

    func nextIncompleteSessionIndex(for book: WordBook) -> Int {
        let count = sessionCount(for: book)
        for index in 0..<count where !isSessionCompleted(bookID: book.id, index: index) {
            return index
        }
        return 0
    }

    func sessionCount(for book: WordBook) -> Int {
        max(1, Int(ceil(Double(book.words.count) / Double(sessionWordCount))))
    }

    func wordsForSession(book: WordBook, index: Int) -> [Word] {
        let start = index * sessionWordCount
        guard start < book.words.count else { return [] }
        let end = min(start + sessionWordCount, book.words.count)
        return Array(book.words[start..<end])
    }

    func completedSessionCount(for bookID: String) -> Int {
        completedSessionKeys().filter { $0.hasPrefix("\(bookID):") }.count
    }

    func isSessionCompleted(bookID: String, index: Int) -> Bool {
        completedSessionKeys().contains(sessionKey(bookID: bookID, index: index))
    }

    func markSessionCompleted(bookID: String, index: Int) {
        var keys = completedSessionKeys()
        keys.insert(sessionKey(bookID: bookID, index: index))
        saveCompletedSessionKeys(keys)
        recordStudyDay()
    }

    func resetSessionHistory(bookID: String? = nil, index: Int? = nil) {
        guard let bookID = bookID else {
            UserDefaults.standard.removeObject(forKey: WordStore.completedSessionsKey)
            return
        }

        if let index = index {
            var keys = completedSessionKeys()
            keys.remove(sessionKey(bookID: bookID, index: index))
            saveCompletedSessionKeys(keys)
            return
        }

        let keys = completedSessionKeys().filter { !$0.hasPrefix("\(bookID):") }
        saveCompletedSessionKeys(keys)
    }

    func wordBook(id: String) -> WordBook? {
        books.first { $0.id == id }
    }

    func addCustomBook(name: String, words: [Word]) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmedName.isEmpty ? "커스텀 단어장" : trimmedName
        customBooks.append(WordBook(id: UUID().uuidString, name: finalName, words: words))
        saveCustomBooks()
    }

    func renameBook(id: String, name: String) {
        guard let index = customBooks.firstIndex(where: { $0.id == id }) else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        customBooks[index].name = trimmedName
        saveCustomBooks()
    }

    func deleteBook(id: String) {
        customBooks.removeAll { $0.id == id }
        saveCustomBooks()
        if UserDefaults.standard.string(forKey: WordStore.quickStudyBookIDKey) == id {
            UserDefaults.standard.set("default", forKey: WordStore.quickStudyBookIDKey)
        }
        resetSessionHistory(bookID: id)
    }

    func moveCustomBook(from sourceIndex: Int, to destinationIndex: Int) {
        guard customBooks.indices.contains(sourceIndex) else { return }
        let book = customBooks.remove(at: sourceIndex)
        let limitedIndex = max(0, min(destinationIndex, customBooks.count))
        customBooks.insert(book, at: limitedIndex)
        saveCustomBooks()
    }

    func updateWord(_ oldWord: Word, inBook id: String, with newWord: Word) {
        guard let bookIndex = customBooks.firstIndex(where: { $0.id == id }) else { return }
        guard let wordIndex = customBooks[bookIndex].words.firstIndex(where: { $0.term == oldWord.term }) else { return }
        customBooks[bookIndex].words[wordIndex] = newWord
        saveCustomBooks()
    }

    func deleteWord(_ word: Word, inBook id: String) {
        guard let bookIndex = customBooks.firstIndex(where: { $0.id == id }) else { return }
        customBooks[bookIndex].words.removeAll { $0.term == word.term }
        saveCustomBooks()
    }

    func resetStudyStates() {
        let resetDefaultWords = WordStore.sampleWords()
        saveDefaultWords(resetDefaultWords)
        customBooks = customBooks.map { book in
            let resetWords = book.words.map {
                Word(
                    term: $0.term,
                    meaning: $0.meaning,
                    reading: $0.reading,
                    example: $0.example,
                    exampleMeaning: $0.exampleMeaning,
                    state: .new
                )
            }
            return WordBook(id: book.id, name: book.name, words: resetWords)
        }
        saveCustomBooks()
        resetSessionHistory()
        UserDefaults.standard.removeObject(forKey: WordStore.studyDaysKey)
    }

    private func recordStudyDay() {
        var days = Set(UserDefaults.standard.stringArray(forKey: WordStore.studyDaysKey) ?? [])
        days.insert(WordStore.dayKey(for: Date()))
        UserDefaults.standard.set(Array(days), forKey: WordStore.studyDaysKey)
    }

    func mark(_ word: Word, as state: StudyState) {
        var defaultWords = WordStore.loadSavedWords()
        if let index = defaultWords.firstIndex(where: { $0.term == word.term }) {
            defaultWords[index].state = state
            saveDefaultWords(defaultWords)
            return
        }

        for bookIndex in customBooks.indices {
            if let wordIndex = customBooks[bookIndex].words.firstIndex(where: { $0.term == word.term }) {
                customBooks[bookIndex].words[wordIndex].state = state
                saveCustomBooks()
                return
            }
        }
    }

    private func saveDefaultWords(_ words: [Word]) {
        guard let data = try? JSONEncoder().encode(words) else { return }
        UserDefaults.standard.set(data, forKey: WordStore.storageKey)
    }

    private func saveCustomBooks() {
        guard let data = try? JSONEncoder().encode(customBooks) else { return }
        UserDefaults.standard.set(data, forKey: WordStore.customBooksKey)
    }

    private static func loadCustomBooks() -> [WordBook] {
        guard
            let data = UserDefaults.standard.data(forKey: customBooksKey),
            let savedBooks = try? JSONDecoder().decode([WordBook].self, from: data)
        else {
            return []
        }

        return savedBooks
    }

    private static func loadSavedWords() -> [Word] {
        let currentSamples = sampleWords()
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let savedWords = try? JSONDecoder().decode([Word].self, from: data),
            !savedWords.isEmpty
        else {
            return currentSamples
        }

        return currentSamples.map { sample in
            let savedState = savedWords.first { $0.term == sample.term }?.state ?? sample.state
            return Word(
                term: sample.term,
                meaning: sample.meaning,
                reading: sample.reading,
                example: sample.example,
                exampleMeaning: sample.exampleMeaning,
                state: savedState
            )
        }
    }

    private func sessionKey(bookID: String, index: Int) -> String {
        "\(bookID):\(index)"
    }

    private func completedSessionKeys() -> Set<String> {
        let savedKeys = UserDefaults.standard.stringArray(forKey: WordStore.completedSessionsKey) ?? []
        return Set(savedKeys)
    }

    private func saveCompletedSessionKeys(_ keys: Set<String>) {
        UserDefaults.standard.set(Array(keys), forKey: WordStore.completedSessionsKey)
    }

    private static func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

final class StudySession {
    private enum StudyAction {
        case memorized(Word)
        case review(Word, counted: Bool)
    }

    private(set) var queue: [Word]
    private(set) var memorizedCount = 0
    private(set) var reviewCount = 0
    private var lastAction: StudyAction?
    private var reviewedTerms: Set<String> = []
    private let bookID: String?
    private let sessionIndex: Int?
    let totalCount: Int

    init(words: [Word], bookID: String? = nil, sessionIndex: Int? = nil) {
        queue = words.shuffled()
        totalCount = words.count
        self.bookID = bookID
        self.sessionIndex = sessionIndex
    }

    var currentWord: Word? {
        queue.first
    }

    var completedCount: Int {
        memorizedCount
    }

    func markCurrentAsMemorized() {
        guard !queue.isEmpty else { return }
        let word = queue.removeFirst()
        memorizedCount += 1
        lastAction = .memorized(word)
        WordStore.shared.mark(word, as: .memorized)
    }

    func markCurrentForReview() {
        guard !queue.isEmpty else { return }
        let word = queue.removeFirst()
        let counted = reviewedTerms.insert(word.term).inserted
        if counted {
            reviewCount += 1
        }
        lastAction = .review(word, counted: counted)
        WordStore.shared.mark(word, as: .review)

        insertReviewWord(word)
    }

    private func insertReviewWord(_ word: Word) {
        guard !queue.isEmpty else {
            queue.insert(word, at: 0)
            return
        }

        let index = Int.random(in: 1...queue.count)
        queue.insert(word, at: index)
    }

    func undoLastAction() -> Bool {
        guard let action = lastAction else { return false }

        switch action {
        case .memorized(let word):
            memorizedCount = max(0, memorizedCount - 1)
            queue.insert(word, at: 0)
            WordStore.shared.mark(word, as: .new)
        case .review(let word, let counted):
            if let index = queue.firstIndex(where: { $0.term == word.term }) {
                queue.remove(at: index)
            }
            if counted {
                reviewedTerms.remove(word.term)
                reviewCount = max(0, reviewCount - 1)
                WordStore.shared.mark(word, as: .new)
            } else {
                WordStore.shared.mark(word, as: .review)
            }
            queue.insert(word, at: 0)
        }

        lastAction = nil
        return true
    }

    func markSessionCompleted() {
        guard let bookID = bookID, let sessionIndex = sessionIndex else { return }
        WordStore.shared.markSessionCompleted(bookID: bookID, index: sessionIndex)
    }
}
