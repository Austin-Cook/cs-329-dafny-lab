class LimitedStack {
  var arr : array<int>  // contents
  var capacity : int    // max number of elements in stack.
  var top : int         // The index of the top of the stack, or -1 if the stack is empty.

  predicate isValid()
    reads this
  {
    && -1 <= top < capacity
    && capacity > 0
    && capacity == arr.Length
  }

  predicate isEmpty()
    reads this
  {
    && top == -1
  }

  predicate isFull()
    reads this
  {
    && top == capacity - 1
  }

  method Init(c : int)
    modifies this
    requires c > 0
    ensures
      && top == -1
      && fresh(arr)
      && capacity == c
      && arr.Length == capacity
      && isEmpty()
      && isValid()
  {
    capacity := c;
    arr := new int[c];
    top := -1;
  }

  method Peek() returns (elem: int)
    requires
      && isValid()
      && top >= 0
    ensures
      && elem == arr[top]
  {
    elem := arr[top];
  }

  method Push(elem : int)
    modifies this`top, this.arr
    requires
      && isValid()
      && !isFull()
    ensures
      && arr[old(top) + 1] == elem
      && (forall i | 0 <= i <= old(top) :: arr[i] == old(arr[i]))
      && top == old(top) + 1
      && isValid()
  {
    arr[top + 1] := elem;
    top := top + 1;
  }

  method Push2(elem : int)
    modifies this.arr, this`top
    requires
      && isValid()
    ensures
      && isValid()
      && !isEmpty()
      && arr[top] == elem
      && arr.Length == old(arr.Length)
      && (if old(isFull()) then
            && top == old(top)
            && (forall i | 0 <= i < capacity - 1 :: arr[i] == old(arr[i + 1]))
          else
            && (forall i | 0 <= i < old(top) :: arr[i] == old(arr[i]))
            && top == old(top) + 1)
  {
    if (isFull()) {
      Shift();
    }
    arr[top + 1] := elem;
    top := top + 1;
  }

  method Pop() returns (elem : int)
    modifies this.arr, this`top
    requires
      && isValid()
      && top >= 0
    ensures
      && isValid()
      && (forall i | 0 <= i < (old(top)) :: arr[i] == old(arr[i]))
      && top == old(top - 1)
      && elem == old(arr[top])
  {
    elem := arr[top];
    top := top - 1;
  }

  // Need for push2 to discard the oldest element
  method Shift()
    requires isValid() && !isEmpty()
    ensures isValid()
    ensures forall i : int :: 0 <= i < capacity - 1 ==> arr[i] == old(arr[i + 1])
    ensures top == old(top) - 1
    modifies this.arr, this`top
  {
    var i : int := 0;
    while (i < capacity - 1 )
      invariant 0 <= i < capacity
      invariant top == old(top)
      invariant forall j : int :: 0 <= j < i ==> arr[j] == old(arr[j + 1])
      invariant forall j : int :: i <= j < capacity ==> arr[j] == old(arr[j])
    {
      arr[i] := arr[i + 1];
      i := i + 1;
    }
    top := top - 1;
  }
}

method Main(){
  var s := new LimitedStack;
  s.Init(3);

  // assertion #1
  assert s.isEmpty() && !s.isFull();

  s.Push(27);
  // assertion #2
  assert !s.isEmpty();

  var e := s.Pop();
  // assertion #3
  assert e == 27;

  s.Push(5);
  s.Push(32);
  s.Push(9);
  // assertion #4
  assert s.isFull();

  var e2 := s.Pop();
  // assertion #5
  assert e2 == 9 && !s.isFull();
  // assertion #6
  assert s.arr[0] == 5;

  s.Push(e2);
  s.Push2(99);

  var e3 := s.Peek();
  // assertion #7
  assert e3 == 99;
  // assertion #8
  assert s.arr[0] == 32;
}
