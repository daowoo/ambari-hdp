# 对象构造过程

## 实例代码
根据以下案例代码来分析Java中对象的构造过程，注意比较下与C++的不同。
```java
public class Super {
    static long time = 10;
    static Object obj = new Object();
    int width = 100;
    static {
        time = 11;
    }
    {
        width = 110;
    }
    public Super() {
        width = 120;
    }
    public static void main(String[] args) {
        Child child = new Child();
        System.out.println("Super.time:"+Super.time);
        System.out.println("Super.obj:"+Super.obj);
        System.out.println("child.width:"+child.width);
        System.out.println("Child.age:"+Child.age);
        System.out.println("Child.str:"+Child.str);
        System.out.println("child.height:"+child.height);
    }
}
class Child extends Super {
    static int age = 20;
    static String str = "str";
    double height = 200;
    static {
        age = 22;
    }
    {
        height = 210;
    }
    public Child() {
        height = 220;
    }
}
```

执行结果：
```output
Super.time:11
Super.obj:java.lang.Object@659e0bfd
child.width:120
Child.age:22
Child.str:str
child.height:220.0
```

## 构造过程分析
1. 用类加载器加载父类，按父类静态变量定义的顺序的为父类所有静态变量分配空间，并赋予父类静态变量默认值
```java
public class Super {
    static long time=10;//此时time=0
    static Object obj=new Object();//此时obj=null
```

2. 用类加载器加载自己，按自己静态变量定义的顺序的为自己所有静态变量分配空间，并赋予自己静态变量默认值
```java
class Child extends Super{
    static int age=20;//此时age=0
    static String str="str";//此时str=null
```

3. 按父类静态变量定义的顺序的为父类所有静态变量赋上定义的值
```java
public class Super {
    static long time=10;//此时time=10
    static Object obj=new Object();//此时obj=new Object()
```

4. 执行父类静态代码块
```java
public class Super {
    static long time=10;
    static Object obj=new Object();
    int width=100;
    static{
        time=11;//静态代码块执行了，这个时候time=11
    }
```

5. 按自己静态变量定义的顺序的为自己所有静态变量赋上定义的值
```java
class Child extends Super{
    static int age=20;//此时age=20
    static String str="str";//此时str="str"
```

6. 执行自己静态代码块
```java
class Child extends Super{
    static int age=20;
    static String str="str";
    double height=200;
    static{
        age=22;//此时age=22
    }
```

7. 为父类实例变量分配空间，并赋予默认值
```java
public class Super {
    static long time=10;
    static Object obj=new Object();
    int width=100;//此时width=0
```

8. 为自己实例变量分配空间，并赋予默认值
```java
class Child extends Super{
    static int age=20;
    static String str="str";
    double height=200;//此时height=0.0
```

9. 按父类实例变量定义的顺序的为父类所有实例变量赋上定义的值
```java
public class Super {
    static long time=10;
    static Object obj=new Object();
    int width=100;//此时width=100
```

10. 执行父类的构造代码块
```java
public class Super {
    static long time=10;
    static Object obj=new Object();
    int width=100;
    static{
        time=11;
    }
    {
        width=110;//此时width=110
    }
```

11. 执行父类的构造方法
```java
public class Super {
    static long time=10;
    static Object obj=new Object();
    int width=100;
    static{
        time=11;
    }
    {
        width=110;
    }
    public Super() {
        width=120;//此时width=120
    }
```

12. 按自己实例变量定义的顺序的为自己所有实例变量赋上定义的值
```java
class Child extends Super{
    static int age=20;
    static String str="str";
    double height=200;//此时height=200.0
```

13. 执行自己的构造代码块
```java
class Child extends Super{
    static int age=20;
    static String str="str";
    double height=200;
    static{
        age=22;
    }
    {
        height=210;//此时height=210.0
    }
```

14. 执行自己的构造方法
```java
class Child extends Super{
    static int age=20;
    static String str="str";
    double height=200;
    static{
        age=22;
    }
    {
        height=210;
    }
    public Child() {
        height=220;//此时height=220.0
    }
```
至此，子对象才正在构造完成，其中1-6属于初始化静态部分，7-14属于初始化实例部分

## 构造过程特点
* 如果一个类的静态部分已经初始化了（已经被类加载器加载了），就不会再重复初始化静态部分，静态部分的初始化只会在类加载器加载一个类的时候初始化一次
* 父类如果还有父类就也依照此顺序先初始化父类的父类，直到Object为止
* 如果执行步骤3,5,9,12赋值操作时，如果发现所赋的值的类还没有初始化，则会先初始化那个引用的类，如果引用的类还有引用的类则也按照此顺序先初始化引用类的引用类，直到所有被引用的类全部被初始化完毕为止

示例：
假如我们在A类中定义一个B类的引用。
```java
public class Super {
    public static void main(String[] args) {
        new A();new B();
    }
}
class A{
    static B b=new B();//这句代码会导致B类会比A类先初始化完成，也就是说B的静态属性会先赋值，静态代码块会先执行。
    static {
        System.out.println("AA");
    }
}
class B{
    static {
        System.out.println("BB");
    }
}
```

打印:
```output
BB
AA
```

假如只定义一个类的引用,而没有赋值,那么不会触发一个类初始化
```java
public class Super {
    public static void main(String[] args) {
        new A();
    }
}
class A{
    static B b;
    static {
        System.out.println("AA");
    }
}
class B{
    static {
        System.out.println("BB");
    }
}
```

打印:
```output
AA
```

结论：只有触发了主动使用才会导致所引用的类被初始化

如果一个类A的所引用的类B里又引用了类A，也就是递归引用的情况，那么会实施java消除递归机制
```java
ublic class Super {
    public static void main(String[] args) {
        new A();
    }
}
class A{
    static B b=new B();
    static {
        System.out.println("AA");
    }
}
class B{
    static A a=new A();
    static {
        System.out.println("BB");
    }
}
```

打印:
```output
BB
AA
```

结论：
初始化引用的类时就像走一条路,java避免递归的机制就是不走之前已经走过的地方

假如在执行3、5、9、12时，发现变量只定义了引用而没有赋值操作，那么该变量将保持默认值
```java
static long time;//保持之前所赋的默认值0
Child child;//保持之前所赋的默认值null
```

## 特殊情况可省略的步骤
* 如果一个类没有父类（如Object类），则它的初始化顺序可以简化成2、5、6、8、12、13、14。
* 如果这个类已经被类加载器加载过了，也就是该类的静态部分已经初始化过了，那么1、2、3、4、5、6都不会执行，总的顺序可以简化为7、8、9、10、11、12、13、14。
* 如果这个类没有被类加载器加载，但它的父类已经被类加载器加载过了，那么总的顺序可以简化为2、5、6、7、8、9、10、11、12、13、14。
