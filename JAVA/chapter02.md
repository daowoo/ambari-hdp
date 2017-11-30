# Java中的Class对象
 Java程序在运行时，`Java Runtime System`一直对所有的对象进行所谓的运行时类型标识，标识产生的这项信息纪录了每个对象所属的类，以便在上/下行造型过程中，虚拟机能够使用运行时类型信息来选择正确的方法去执行，而用来保存这些类型信息的类就是Class类。

 ## 特点
 * Class类封装一个对象和接口运行时的状态，当装载类时，Class类型的对象自动创建,一旦这个类的Class对象被载入内存，它就被用来创建这个类的所有对象。
 * Class没有公共构造方法，Class对象是在加载类时由JVM以及通过调用类加载器中的`defineClass`方法自动构造的，因此不能显式地声明一个Class对象。
 * Class对象用来创建其它java类的实例的对象，其实Class对象就是java类编译后生成的.class文件，它包含了与类有关的信息。

但是当我们想自己加载这个类的Class对象怎么办呢?
* Class.forName("类名字符串"),需要注意的是，类名字符串必须是全称，即包名+类名
* 类字面常量法：类名.class
* 实例对象.getClass()

## 示例
测试代码：
```java
class Candy{
    static{System.out.println("Loading Candy");}
}
class Gum{
    static{System.out.println("Loading Gum");}
}
class Cookie{
    static{System.out.println("Loading Cookie");}
    public Cookie(){
        System.out.println("initializing Cookie");
    }
}

public class SweetShop {
    public static void main(String[] args){
        Class classType;
        System.out.println("inside main");
        try{
            classType=Class.forName("typeInfo.Gum");
        }catch(ClassNotFoundException e){
            System.out.println("Couldn't not find Gum");
        }
        System.out.println("After creating Class.forName(\"Gum\")");
        classType=Candy.class;
        System.out.println("After creating Candy");
        Cookie cookie=new Cookie();
        classType=cookie.getClass();
        System.out.println("After creating Cookie");
    }
}
```

结果输出：
```output
inside main
Couldn't not find Gum
After creating Class.forName("Gum")
After creating Candy
Loading Cookie
initializing Cookie
After creating Cookie

进程已结束,退出代码0
```

从输出中可以看出，Class对象仅在需要的时候才被加载（我们在Java 对象及其内存控制一文中说过：static初始化是在类加载时进行的）。 为什么没有打印出“Loading Candy”呢？因为，使用类字面常量法创建对Class对象的引用时，不会自动的初始化该Class对象。

## 泛化的Class对象
由于普通Class引用指向的是它所指向的对象的确切类型。在Java引入泛型的概念之后，Java SE5的设计者将Class引用的类型通过使用泛型限定变得更具体了。再看我们上面的程序，一个Class classType既可以指向Candy类的Class对象也可以指向Gum类的Class对象还可以指向Cookie类的Class对象。这就很像我们编程时使用Object作为引用变量的类型一样。

但当我们用泛型限定了上面代码的classType之后，便会有错误出现了：
```java
    public static void main(String[] args){
        Class<Candy> classType;
        System.out.println("inside main");
        try{
            classType=Class.forName("typeInfo.Gum");
        }catch(ClassNotFoundException e){
            System.out.println("Couldn't not find Gum");
        }
        System.out.println("After creating Class.forName(\"Gum\")");
        classType=Candy.class;
        System.out.println("After creating Candy");
        Cookie cookie=new Cookie();
        classType=cookie.getClass();
        System.out.println("After creating Cookie");
    }
```

```output
F:\works\spring-boot-exmple\Testclass\src\main\java\SweetShop.java
错误:(21, 36) java: 不兼容的类型: java.lang.Class<capture#1, 共 ?>无法转换为java.lang.Class<Candy>
错误:(29, 34) java: 不兼容的类型: java.lang.Class<capture#2, 共 ? extends Cookie>无法转换为java.lang.Class<Candy>
```

现在当我们需要放宽条件，即需要创建一个Class引用，它被限定为某种类型，或者该类型的任何子类型，这是我们就需要使用通配符"?"与extends关键字相结合，创建一个“范围”：
```java
public class NumberClassObj {
    public static void main(String[] args) {
        Class<? extends Number> numType=int.class;
        numType=double.class;
        numType=Number.class;
    }
}
```
