defmodule Lab3 do
  # ---------- LINEAR ----------
  def linear([{x0,y0},{x1,y1}], x) do
    y0 + (y1 - y0) * ((x - x0)/(x1-x0))
  end

  # ---------- LAGRANGE ----------
  def lagrange(points, x) do
    Enum.with_index(points)
    |> Enum.reduce(0.0, fn {{xi, yi}, i}, acc ->
      li =
        Enum.with_index(points)
        |> Enum.reduce(1.0, fn {{xj,_}, j}, prod ->
          if i != j, do: prod*(x-xj)/(xi-xj), else: prod
        end)

      acc + yi*li
    end)
  end

  # ---------- NEWTON ----------
  def newton_fun(points) do
    xs = Enum.map(points, &elem(&1,0))
    coeffs = newton_coeffs(points)

    fn x ->
      Enum.with_index(coeffs)
      |> Enum.reduce(0.0, fn {c,i}, acc ->
        mult =
          if i == 0 do
            1.0
          else
            0..(i-1)
            |> Enum.reduce(1.0, fn j,t -> t*(x-Enum.at(xs,j)) end)
          end

        acc + c*mult
      end)
    end
  end

  defp newton_coeffs(points) do
    xs = Enum.map(points,&elem(&1,0))
    ys = Enum.map(points,&elem(&1,1))

    build_div_diff(ys,xs) |> Enum.map(&hd/1)
  end

  defp build_div_diff(cur,xs,acc \\ [])
  defp build_div_diff([y], _xs, acc), do: Enum.reverse([[y]|acc])

  defp build_div_diff(cur,xs,acc) do
    k = length(acc)
    next =
      0..(length(cur)-2)
      |> Enum.map(fn i ->
        (Enum.at(cur,i+1)-Enum.at(cur,i))/
        (Enum.at(xs,i+k+1)-Enum.at(xs,i))
      end)

    build_div_diff(next,xs,[cur|acc])
  end
end

# ===== CLI =====

defmodule Main do
  def run(opts) do
    file = opts[:file] || abort("Use --file FILE")
    x = opts[:x] || abort("Use --x NUM")

    x =
      case Float.parse(x) do
        {val,_}-> val
        _-> abort("x must be float")
      end

    points = load_points(file)

    cond do
      opts[:linear] ->
        if length(points) != 2,
          do: abort("Linear: need exactly 2 points")

        IO.puts Lab3.linear(points,x)

      opts[:lagrange] ->
        IO.puts Lab3.lagrange(points,x)

      opts[:newton] ->
        f = Lab3.newton_fun(points)
        IO.puts f.(x)

      true ->
        abort("Select method: --lagrange / --newton / --linear")
    end
  end

  defp load_points(file) do
    File.stream!(file)
    |> Stream.map(&String.trim/1)
    |> Stream.reject(&(&1==""))
    |> Enum.map(fn line ->
      [sx,sy] = String.split(line,~r/[,; ]+/)
      {String.to_float(sx), String.to_float(sy)}
    end)
  end

  defp abort(msg) do
    IO.puts(:stderr, msg)
    System.halt(1)
  end
end

{opts,_,_} =
  OptionParser.parse(System.argv(),
    switches: [
      file: :string,
      x: :string,
      linear: :boolean,
      newton: :boolean,
      lagrange: :boolean
    ]
  )

Main.run(opts)
