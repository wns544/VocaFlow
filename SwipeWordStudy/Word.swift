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
    var state: StudyState
}

final class WordStore {
    static let shared = WordStore()

    private static let storageKey = "savedWords"
    private(set) var words: [Word]

    private init() {
        words = WordStore.loadSavedWords()
    }

    func resetStudyStates() {
        words = words.map {
            Word(term: $0.term, meaning: $0.meaning, reading: $0.reading, example: $0.example, state: .new)
        }
        saveWords()
    }

    func mark(_ word: Word, as state: StudyState) {
        guard let index = words.firstIndex(where: { $0.term == word.term }) else { return }
        words[index].state = state
        saveWords()
    }

    private func saveWords() {
        guard let data = try? JSONEncoder().encode(words) else { return }
        UserDefaults.standard.set(data, forKey: WordStore.storageKey)
    }

    private static func loadSavedWords() -> [Word] {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let savedWords = try? JSONDecoder().decode([Word].self, from: data),
            !savedWords.isEmpty
        else {
            return sampleWords()
        }

        return savedWords
    }
}

final class StudySession {
    private(set) var queue: [Word]
    let totalCount: Int

    init(words: [Word]) {
        queue = words.shuffled()
        totalCount = words.count
    }

    var currentWord: Word? {
        queue.first
    }

    var completedCount: Int {
        totalCount - queue.count
    }

    func markCurrentAsMemorized() {
        guard !queue.isEmpty else { return }
        let word = queue.removeFirst()
        WordStore.shared.mark(word, as: .memorized)
    }

    func markCurrentForReview() {
        guard !queue.isEmpty else { return }
        let word = queue.removeFirst()
        WordStore.shared.mark(word, as: .review)

        if !queue.isEmpty {
            let index = min(2, queue.count)
            queue.insert(word, at: index)
        }
    }
}
