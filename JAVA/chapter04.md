# Java类中各成分加载顺序和内存中的存放位置

## 什么时候会加载类？
使用到类中的内容时加载：有三种情况
* 创建对象：new StaticCode();
* 使用类中的静态成员：StaticCode.num=9; StaticCode.show();
* 在命令行中运行：java StaticCodeDemo

## 类所有内容加载顺序和内存中的存放位置
### 构造过程分析
```java
Person p=new Person("zhangsan",20);
```

该句话所做的事情：
* 在栈内存中，开辟main函数的空间，建立main函数的变量 p。
* 加载类文件：因为new要用到Person.class,所以要先从硬盘中找到Person.class类文件，并加载到内存中。加载类文件时，除了非静态成员变量（对象的特有属性）不会被加载，其它的都会被加载。记住：加载，是将类文件中的一行行内容存放到了内存当中，并不会执行任何语句。---->加载时期，即使有输出语句也不会执行。
  - 静态成员变量（类变量）	----->方法区的静态部分
  - 静态方法 ----->方法区的静态部分
  - 非静态方法（包括构造函数）	----->方法区的非静态部分
  - 静态代码块	----->方法区的静态部分
  - 构造代码块	----->方法区的静态部分
> 注意：在Person.class文件加载时，静态方法和非静态方法都会加载到方法区中，只不过要调用到非静态方法时需要先实例化一个对象，对象才能调用非静态方法。如果让类中所有的非静态方法都随着对象的实例化而建立一次，那么会大量消耗内存资源，所以才会让所有对象共享这些非静态方法，然后用this关键字指向调用非静态方法的对象。

* 执行类中的静态代码块：如果有的话，对Person.class类进行初始化。
* 开辟空间：在堆内存中开辟空间，分配内存地址。
* 默认初始化：在堆内存中建立 对象的特有属性，并进行默认初始化。
* 显示初始化：对属性进行显示初始化。
* 构造代码块：执行类中的构造代码块，对对象进行构造代码块初始化。
* 构造函数初始化：对对象进行对应的构造函数初始化。
* 将内存地址赋值给栈内存中的变量p。

### 引用调优分析
```java
p.setName("lisi");
```

* 在栈内存中开辟setName方法的空间，里面有：对象的引用this，临时变量name
* 将p的值赋值给this,this就指向了堆中调用该方法的对象。
* 将"lisi" 赋值给临时变量name。
* 将临时变量的值赋值给this的name。

### 静态调用分析
```java
Person.showCountry();
```

* 在栈内存中，开辟showCountry()方法的空间，里面有：类名的引用Person。
* Person指向方法区中Person类的静态方法区的地址。
* 调用静态方法区中的country，并输出。

>注意：要想使用类中的成员，必须调用。通过什么调用？有：类名、this、super

## 静态代码块、构造代码块和构造函数的区别
* 静态代码块：用于给类初始化，类加载时就会被加载执行，只加载一次。
* 构造代码块：用于给对象初始化的。只要建立对象该部分就会被执行，且优先于构造函数。
* 构造函数： 给对应对象初始化的，建立对象时，选择相应的构造函数初始化对象。
* 创建对象时，三者被加载执行顺序：静态代码块--->构造代码块--->构造函数

### 利用代码进行测试
```java
class Person {
  private String name;
  private int age=0;
  private static String country="cn";

Person(String name,int age) {
  this.name=name;
  this.age=age;
}

static {
System.out.println("静态代码块被执行");
}

{ System.out.println(name+"..."+age);	}

public void setName(String name) {
  this.name=name;
}

public void speak() {
  System.out.println(this.name+"..."+this.age);
}

public static void showCountry() {
  System.out.println("country="+country);
}
}

class StaticDemo {

static {
  System.out.println("StaticDemo 静态代码块1");
}

public static void main(String[] args) {
  Person p=new Person("zhangsan",100);
  p.setName("lisi");
  p.speak();
  Person.showCountry();
}

static {
  System.out.println("StaticDemo 静态代码块2");
}
}
```

> 输出结果：
> ```
> StaticDemo 静态代码块1
> StaticDemo 静态代码块2
> 静态代码块被执行
> null...0 //构造代码块
> lisi...100	//speak()
> country=cn	//showCountry()
> ```
