# Freddie: Elixir Socket Framework

Freddie is a socket framework for Elixir.

## 1. Features
1. Use non blocking socket IO to communicate with clients
2. Can optionally encrypt the message
3. Create fault-tolerance applications based on Erlang OTP
4. Ship Protobuf as default message serialization library

## 2. Todo
1. Provides Reliable UDP communication(Guarantee the latest order or Guaranteed both sequence and retransmission)
2. Optimize network code
3. Divide transmission into reliable and unreliable

## 3. examples

[example projects](https://github.com/kernelgarden/freddie_example)