"""sklearn_bridge.py - Python-side bridge for Janus ML integration"""

from sklearn.tree import DecisionTreeClassifier
from sklearn.cluster import KMeans
import numpy as np


def _check_rows(rows, name):
    if rows is None or len(rows) == 0:
        raise ValueError(f"{name} must be a non-empty list of rows")
    width = len(rows[0])
    if width == 0:
        raise ValueError(f"{name} rows must be non-empty lists")
    for row in rows:
        if len(row) != width:
            raise ValueError(
                f"{name} rows must all have the same length "
                f"(expected {width}, got {len(row)})")
    return width


def classify(train_data, test_data):
    """Train a DecisionTreeClassifier and predict on test data.

    train_data rows are labelled: [f1, ..., fN, label].
    test_data rows are unlabelled feature vectors: [f1, ..., fN].
    """
    train_width = _check_rows(train_data, "train_data")
    _check_rows(test_data, "test_data")
    if train_width < 2:
        raise ValueError(
            "train_data rows need at least one feature and a label")
    X_train = [row[:-1] for row in train_data]
    y_train = [row[-1] for row in train_data]
    X_test = [list(row) for row in test_data]
    for row in X_test:
        if len(row) != train_width - 1:
            raise ValueError(
                f"test_data rows must have {train_width - 1} features, "
                f"got {len(row)}")

    clf = DecisionTreeClassifier(random_state=42)
    clf.fit(X_train, y_train)
    predictions = clf.predict(X_test)
    return predictions.tolist()


def cluster(data, n_clusters):
    """Run KMeans clustering and return cluster labels."""
    _check_rows(data, "data")
    if not isinstance(n_clusters, int) or n_clusters < 1:
        raise ValueError("n_clusters must be a positive integer")
    if n_clusters > len(data):
        raise ValueError(
            f"n_clusters={n_clusters} exceeds number of samples "
            f"{len(data)}")
    X = np.array(data)
    kmeans = KMeans(n_clusters=n_clusters, random_state=42, n_init=10)
    kmeans.fit(X)
    return kmeans.labels_.tolist()
