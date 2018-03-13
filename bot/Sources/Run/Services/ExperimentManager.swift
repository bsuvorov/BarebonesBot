import Foundation

public enum Experiment: String {
    case SomeExperiment
    
    static let allValues = [SomeExperiment]
}

public final class ExperimentManager {
    static public func isSubscriber(_ subscriber: Subscriber, inExperiment: Experiment) -> Bool {
        return false
    }

    static public func listExperimentsForSubscriber(_ subscriber: Subscriber) -> String {
        var experiments = [String]()
        for experiment in Experiment.allValues {
            if isSubscriber(subscriber, inExperiment: experiment) {
                experiments.append(experiment.rawValue)
            }
        }

        return experiments.joined(separator: " ")
    }
}
