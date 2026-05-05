"""sklearn_bridge.py - Python-side bridge for Janus ML integration"""

from sklearn.tree import DecisionTreeClassifier
from sklearn.cluster import KMeans
import numpy as np

def classify(train_data, test_data):
    """Train a DecisionTreeClassifier and predict on test data."""
    X_train = [row[:-1] for row in train_data]
    y_train = [row[-1] for row in train_data]
    X_test = [row[:-1] for row in test_data]

    clf = DecisionTreeClassifier()
    clf.fit(X_train, y_train)
    predictions = clf.predict(X_test)
    return predictions.tolist()

def cluster(data, n_clusters):
    """Run KMeans clustering and return cluster labels."""
    X = np.array(data)
    kmeans = KMeans(n_clusters=n_clusters, random_state=42, n_init=10)
    kmeans.fit(X)
    return kmeans.labels_.tolist()
