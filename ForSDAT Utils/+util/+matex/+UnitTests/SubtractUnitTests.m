import util.matex.*;
disp('Starting util.matex.Subtract class unit tests');
%%
test = Simple.UnitTests.UnitTesting('util.matex.Subtract.ctor');

exp = Subtract(Scalar(10), X);
test.checkExpectation(10, exp.left, 'Subtract(10,x).left.equals(10)');
test.checkExpectation(X, exp.right, 'Subtract(10,x).right.equals(x)');

exp = Subtract(X, Scalar(10));
test.checkExpectation(true, exp.right.equals(10), 'Subtract(x,10).right.equals(10)');
test.checkExpectation(true, exp.left.equals(X), 'Subtract(x,10).left.equals(x)');

exp = Subtract(X, Subtract(X, X));
test.checkExpectation(true, exp.left.equals(X), 'Subtract(X,Subtract(X,X)).left.equals(x)');
test.checkExpectation(true, isa(exp.right, 'Subtract'), 'Subtract(X,Subtract(X,X)).left.equals(x)');
test.checkExpectation(true, exp.right.left.equals(X), 'Subtract(X,Subtract(X,X)).right.left.equals(x)');
test.checkExpectation(true, exp.right.right.equals(X), 'Subtract(X,Subtract(X,X)).right.right.equals(x)');

test.evaluateAllExpectations();
%%
test = Simple.UnitTests.UnitTesting('util.matex.Subtract.equals');

exp = Subtract(Scalar(10), X);
test.checkExpectation(true, exp.equals(Subtract(Scalar(10), X)), 'Subtract(10,x).equals(Subtract(10, X))');
test.checkExpectation(false, exp.equals(Subtract(X, Scalar(10))), 'Subtract(10,x).equals(Subtract(X, 10))');
test.checkExpectation(false, exp.equals(Subtract(X, X)), 'Subtract(10,x).equals(Subtract(X, X))');
test.checkExpectation(false, exp.equals(Add(Scalar(10), X)), 'Subtract(10,x).equals(Add(10, X))');
test.checkExpectation(false, exp.equals(Multiply(Scalar(10), X)), 'Subtract(10,x).equals(Multiply(10, X))');
test.checkExpectation(false, exp.equals(Subtract(Scalar(10), Subtract(Scalar(10), X))), 'Subtract(10,x).equals(Subtract(X, Subtract(10, X)))');
test.checkExpectation(true, exp.equals(Subtract(Subtract(Scalar(10), Zero), X)), 'Subtract(10,x).equals(Subtract(0, Subtract(10, X)))');
test.checkExpectation(false, exp.equals(Subtract(Zero, Subtract(Scalar(10), X))), 'Subtract(10,x).equals(Subtract(0, Subtract(10, X)))');
test.checkExpectation(false, exp.equals(Subtract(X, Subtract(Scalar(10), Zero))), 'Subtract(10,x).equals(Subtract(X, Subtract(10, 0)))');
test.checkExpectation(true, exp.equals(Subtract(Scalar(10), Subtract(X, Zero))), 'Subtract(10,x).equals(Subtract(10, Subtract(X, 0)))');
test.checkExpectation(false, exp.equals(Subtract(X, Subtract(Scalar(10), One))), 'Subtract(10,x).equals(Subtract(X, Subtract(10, 1)))');
test.checkExpectation(false, exp.equals(Subtract(X, Multiply(Scalar(10), One))), 'Subtract(10,x).equals(Subtract(X, Multiply(10, 1)))');
test.checkExpectation(true, exp.equals(Subtract(Scalar(10), Multiply(X, One))), 'Subtract(10,x).equals(Subtract(10, Multiply(X, 1)))');

test.evaluateAllExpectations();
%%
test = Simple.UnitTests.UnitTesting('util.matex.Subtract.invoke');

exp = Subtract(Scalar(10), X);
test.checkExpectation(9, exp.invoke(1), 'Subtract(10,x).invoke(1)');
test.checkExpectation(10-(1:10), exp.invoke(1:10), 'Subtract(10,x).invoke(1:10)');
test.checkExpectation(10-(-10:10), exp.invoke(-10:10), 'Subtract(10,x).invoke(-10:10)');
test.checkExpectation(10-(-10:0.5:10), exp.invoke(-10:0.5:10), 'Subtract(10,x).invoke(-10:0.5:10)');

exp = Subtract(X, Scalar(10));
test.checkExpectation(-9, exp.invoke(1), 'Subtract(10,x).invoke(1)');
test.checkExpectation((1:10)-10, exp.invoke(1:10), 'Subtract(10,x).invoke(1:10)');
test.checkExpectation((-10:10)-10, exp.invoke(-10:10), 'Subtract(10,x).invoke(-10:10)');
test.checkExpectation((-10:0.5:10)-10, exp.invoke(-10:0.5:10), 'Subtract(10,x).invoke(-10:0.5:10)');

test.evaluateAllExpectations();
%%
test = Simple.UnitTests.UnitTesting('util.matex.Subtract.derive');

exp = Subtract(Scalar(10), X);
test.checkExpectation(Minus(One), exp.derive(), 'Subtract(10,x).derive()');
test.checkExpectation(Minus(One), exp.derive(1), 'Subtract(10,x).derive(1)');
test.checkExpectation(Zero, exp.derive(2), 'Subtract(10,x).derive(2)');

test.evaluateAllExpectations();