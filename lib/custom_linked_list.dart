import 'package:flutter/foundation.dart';

class CustomLinkedList<E extends LinkedListEntry<E>> extends Iterable<E> {
  int _modificationCount = 0;
  int _length = 0;
  E _first;

  /// Construct a new empty linked list.
  CustomLinkedList();

  void setFirst(E entry) {
    if (entry._list != this) return;
    if (isEmpty) {
      addFirst(entry);
      return;
    }
    firstWhere((element) {
      bool b = element == entry;
      if (!b) {
        _length--;
      }
      return b;
    }, orElse: () => null);
    entry._previous = _first._previous;
    _first._previous._next = entry;
    _first = entry;
  }

  void setLast(E entry) {
    if (entry._list != this) return;
    if (isEmpty) {
      addFirst(entry);
      return;
    }
    int tmpLength = 0;
    firstWhere((element) {
      tmpLength++;
      return element == entry;
    }, orElse: () => null);
    _length = tmpLength;
    _first._previous = entry;
    entry._next = _first;
  }

  /// Add [entry] to the beginning of the linked list.
  void addFirst(E entry) {
    _insertBefore(_first, entry, updateFirst: true);
    _first = entry;
  }

  /// Add [entry] to the end of the linked list.
  void add(E entry) {
    _insertBefore(_first, entry, updateFirst: false);
  }

  /// Add [entries] to the end of the linked list.
  void addAll(Iterable<E> entries) {
    entries.forEach(add);
  }

  /// Remove [entry] from the linked list.
  ///
  /// Returns false and does nothing if [entry] is not in this linked list.
  ///
  /// This is equivalent to calling `entry.unlink()` if the entry is in this
  /// list.
  bool remove(E entry) {
    if (entry._list != this) return false;
    _unlink(entry); // Unlink will decrement length.
    return true;
  }

  Iterator<E> get iterator => _LinkedListIterator<E>(this);

  int get length => _length;

  /// Remove all elements from this linked list.
  void clear() {
    _modificationCount++;
    if (isEmpty) return;

    E next = _first;
    do {
      E entry = next;
      next = entry._next;
      entry._next = entry._previous = entry._list = null;
    } while (!identical(next, _first));

    _first = null;
    _length = 0;
  }

  E get first {
    if (isEmpty) {
      throw StateError('No such element');
    }
    return _first;
  }

  E get last {
    if (isEmpty) {
      throw StateError('No such element');
    }
    return _first._previous;
  }

  E get single {
    if (isEmpty) {
      throw StateError('No such element');
    }
    if (_length > 1) {
      throw StateError('Too many elements');
    }
    return _first;
  }

  /// Call [action] with each entry in this linked list.
  ///
  /// It's an error if [action] modifies the linked list.
  void forEach(void action(E entry)) {
    int modificationCount = _modificationCount;
    if (isEmpty) return;

    E current = _first;
    do {
      action(current);
      if (modificationCount != _modificationCount) {
        throw ConcurrentModificationError(this);
      }
      current = current._next;
    } while (!identical(current, _first));
  }

  bool get isEmpty => _length == 0;

  /// Inserts [newEntry] as last entry of the list.
  ///
  /// If [updateFirst] is true and [entry] is the first entry in the list,
  /// updates the [_first] field to point to the [newEntry] as first entry.
  void _insertBefore(E entry, E newEntry, {@required bool updateFirst}) {
    if (newEntry.list != null) {
      throw StateError('LinkedListEntry is already in a LinkedList');
    }
    _modificationCount++;

    newEntry._list = this;
    if (isEmpty) {
      assert(entry == null);
      newEntry._previous = newEntry._next = newEntry;
      _first = newEntry;
      _length++;
      return;
    }
    E predecessor = entry._previous;
    E successor = entry;
    newEntry._previous = predecessor;
    newEntry._next = successor;
    predecessor._next = newEntry;
    successor._previous = newEntry;
    if (updateFirst && identical(entry, _first)) {
      _first = newEntry;
    }
    _length++;
  }

  void _unlink(E entry) {
    _modificationCount++;
    entry._next._previous = entry._previous;
    E next = entry._previous._next = entry._next;
    _length--;
    entry._list = entry._next = entry._previous = null;
    if (isEmpty) {
      _first = null;
    } else if (identical(entry, _first)) {
      _first = next;
    }
  }
}

class _LinkedListIterator<E extends LinkedListEntry<E>> implements Iterator<E> {
  final CustomLinkedList<E> _list;
  final int _modificationCount;
  E _current;
  E _next;
  bool _visitedFirst;

  _LinkedListIterator(CustomLinkedList<E> list)
      : _list = list,
        _modificationCount = list._modificationCount,
        _next = list._first,
        _visitedFirst = false;

  E get current {
    final cur = _current;
    return (cur != null) ? cur : cur as E;
  }

  bool moveNext() {
    if (_modificationCount != _list._modificationCount) {
      throw ConcurrentModificationError(this);
    }
    if (_list.isEmpty || (_visitedFirst && identical(_next, _list.first))) {
      _current = null;
      return false;
    }
    _visitedFirst = true;
    _current = _next;
    _next = _next._next;
    return true;
  }
}

/// An object that can be an element in a [LinkedList].
///
/// All elements of a `LinkedList` must extend this class.
/// The class provides the internal links that link elements together
/// in the `LinkedList`, and a reference to the linked list itself
/// that an element is currently part of.
///
/// An entry can be in at most one linked list at a time.
/// While an entry is in a linked list, the [list] property points to that
/// linked list, and otherwise the `list` property is `null`.
///
/// When created, an entry is not in any linked list.
abstract class LinkedListEntry<E extends LinkedListEntry<E>> {
  CustomLinkedList<E> _list;
  E _next;
  E _previous;

  /// Get the linked list containing this element.
  ///
  /// Returns `null` if this entry is not currently in any list.
  CustomLinkedList<E> get list => _list;

  /// Unlink the element from its linked list.
  ///
  /// The entry must currently be in a linked list when this method is called.
  void unlink() {
    _list._unlink(this as E);
  }

  /// Return the successor of this element in its linked list.
  ///
  /// Returns `null` if there is no successor in the linked list, or if this
  /// entry is not currently in any list.
  E get next {
    if (_list == null || identical(_list.first, _next)) return null;
    return _next;
  }

  /// Return the predecessor of this element in its linked list.
  ///
  /// Returns `null` if there is no predecessor in the linked list, or if this
  /// entry is not currently in any list.
  E get previous {
    if (_list == null || identical(this, _list.first)) return null;
    return _previous;
  }

  /// Insert an element after this element in this element's linked list.
  ///
  /// This entry must be in a linked list when this method is called.
  /// The [entry] must not be in a linked list.
  void insertAfter(E entry) {
    _list._insertBefore(_next, entry, updateFirst: false);
  }

  /// Insert an element before this element in this element's linked list.
  ///
  /// This entry must be in a linked list when this method is called.
  /// The [entry] must not be in a linked list.
  void insertBefore(E entry) {
    _list._insertBefore(this as E, entry, updateFirst: true);
  }
}
