import PostgresNIO
import NIOPosix

let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)

let config = PostgresConnection.Configuration(
    host: "localhost",
    port: 5432,
    username: "postgres",
    password: "postgres",
    database: "postgres",
    tls: .disable
)

do {
    let connection = try PostgresConnection.connect(
        on: group.next(),
        configuration: config
    ).wait()

    print("Connected ✅")

    try connection.close().wait()
} catch {
    print("Error:", error)
}

try group.syncShutdownGracefully()