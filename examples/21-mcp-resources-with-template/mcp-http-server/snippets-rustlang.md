## Hello World
Basic program structure and main function
```rust
fn main() {
    println!("Hello, World!");
}
```

----------

## Variable Declaration
Different ways to declare and initialize variables
```rust
fn main() {
    let name = "John";           // Immutable
    let mut age = 30;           // Mutable
    let city: &str = "New York"; // With type annotation
    
    age += 1; // Modify mutable variable
    
    println!("Name: {}, Age: {}, City: {}", name, age, city);
}
```
